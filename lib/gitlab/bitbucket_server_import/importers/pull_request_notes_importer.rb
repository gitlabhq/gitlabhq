# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class PullRequestNotesImporter
        include ::Gitlab::Import::MergeRequestHelpers
        include ::Gitlab::Import::UsernameMentionRewriter
        include Loggable
        include ::Import::PlaceholderReferences::Pusher

        def initialize(project, hash)
          @project = project
          @user_finder = UserFinder.new(project)
          @formatter = Gitlab::ImportFormatter.new
          @object = hash.with_indifferent_access
        end

        def execute
          return unless import_data_valid?

          log_info(import_stage: 'import_pull_request_notes', message: 'starting', iid: object[:iid])

          merge_request = project.merge_requests.find_by(iid: object[:iid]) # rubocop: disable CodeReuse/ActiveRecord

          import_notes_in_batch(merge_request) if merge_request

          log_info(import_stage: 'import_pull_request_notes', message: 'finished', iid: object[:iid])
        end

        private

        attr_reader :object, :project, :formatter, :user_finder

        def import_notes_in_batch(merge_request)
          activities = client.activities(project_key, repository_slug, merge_request.iid)

          comments, other_activities = activities.partition(&:comment?)

          merge_event = other_activities.find(&:merge_event?)
          import_merge_event(merge_request, merge_event) if merge_event

          inline_comments, pr_comments = comments.partition(&:inline_comment?)

          import_inline_comments(inline_comments.map(&:comment), merge_request)
          import_standalone_pr_comments(pr_comments.map(&:comment), merge_request)

          approved_events = other_activities.select(&:approved_event?)
          approved_events.each { |event| import_approved_event(merge_request, event) }
        end

        def import_data_valid?
          project.import_data&.credentials && project.import_data&.data
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def import_merge_event(merge_request, merge_event)
          log_info(import_stage: 'import_merge_event', message: 'starting', iid: merge_request.iid)

          user_id = if user_mapping_enabled?(project)
                      user_finder.uid(
                        username: merge_event.committer_username,
                        display_name: merge_event.committer_name
                      )
                    else
                      user_finder.find_user_id(by: :email, value: merge_event.committer_email)
                    end

          user_id ||= project.creator_id

          timestamp = merge_event.merge_timestamp
          merge_request.update({ merge_commit_sha: merge_event.merge_commit })

          metric = MergeRequest::Metrics.find_or_initialize_by(merge_request: merge_request)
          metric.update(merged_by_id: user_id, merged_at: timestamp)
          push_reference(project, metric, :merged_by_id, merge_event.committer_username)

          log_info(import_stage: 'import_merge_event', message: 'finished', iid: merge_request.iid)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def import_approved_event(merge_request, approved_event)
          log_info(
            import_stage: 'import_approved_event',
            message: 'starting',
            iid: merge_request.iid,
            event_id: approved_event.id
          )

          user_id = if user_mapping_enabled?(project)
                      user_finder.uid(
                        username: approved_event.approver_username,
                        display_name: approved_event.approver_name
                      )
                    else
                      user_finder.find_user_id(by: :email, value: approved_event.approver_email)
                    end

          return unless user_id

          submitted_at = approved_event.created_at || merge_request.updated_at

          approval, approval_note = create_approval!(project.id, merge_request.id, user_id, submitted_at)
          push_reference(project, approval, :user_id, approved_event.approver_username) if approval
          push_reference(project, approval_note, :author_id, approved_event.approver_username) if approval_note

          reviewer = create_reviewer!(merge_request.id, user_id, submitted_at)
          push_reference(project, reviewer, :user_id, approved_event.approver_username) if reviewer

          log_info(
            import_stage: 'import_approved_event',
            message: 'finished',
            iid: merge_request.iid,
            event_id: approved_event.id
          )
        end

        def import_inline_comments(inline_comments, merge_request)
          log_info(import_stage: 'import_inline_comments', message: 'starting', iid: merge_request.iid)

          inline_comments.each do |comment|
            position = build_position(merge_request, comment)
            parent = create_diff_note(merge_request, comment, position)

            next unless parent&.persisted?

            discussion_id = parent.discussion_id

            comment.comments.each do |reply|
              create_diff_note(merge_request, reply, position, discussion_id)
            end
          end

          log_info(import_stage: 'import_inline_comments', message: 'finished', iid: merge_request.iid)
        end

        def create_diff_note(merge_request, comment, position, discussion_id = nil)
          attributes = pull_request_comment_attributes(comment)
          attributes.merge!(position: position, type: 'DiffNote')
          attributes[:discussion_id] = discussion_id if discussion_id

          note = merge_request.notes.build(attributes)

          if note.valid?
            note.save
            push_reference(project, note, :author_id, comment.author_username)
            return note
          end

          log_info(import_stage: 'create_diff_note', message: 'creating fallback DiffNote', iid: merge_request.iid)

          # Bitbucket Server supports the ability to comment on any line, not just the
          # line in the diff. If we can't add the note as a DiffNote, fallback to creating
          # a regular note.
          create_fallback_diff_note(merge_request, comment, position)
        rescue StandardError => e
          Gitlab::ErrorTracking.log_exception(
            e,
            import_stage: 'create_diff_note', comment_id: comment.id, error: e.message
          )

          nil
        end

        def create_fallback_diff_note(merge_request, comment, position)
          attributes = pull_request_comment_attributes(comment)
          note = "*Comment on"

          note += " #{position.old_path}:#{position.old_line} -->" if position.old_line
          note += " #{position.new_path}:#{position.new_line}" if position.new_line
          note += "*\n\n#{comment.note}"

          attributes[:note] = note
          note = merge_request.notes.create!(attributes)
          push_reference(project, note, :author_id, comment.author_username)
          note
        end

        def build_position(merge_request, pr_comment)
          params = {
            diff_refs: merge_request.diff_refs,
            old_path: pr_comment.file_path,
            new_path: pr_comment.file_path,
            old_line: pr_comment.old_pos,
            new_line: pr_comment.new_pos
          }

          Gitlab::Diff::Position.new(params)
        end

        def import_standalone_pr_comments(pr_comments, merge_request)
          log_info(import_stage: 'import_standalone_pr_comments', message: 'starting', iid: merge_request.iid)

          pr_comments.each do |comment|
            note = merge_request.notes.create!(pull_request_comment_attributes(comment))
            push_reference(project, note, :author_id, comment.author_username)

            comment.comments.each do |replies|
              note = merge_request.notes.create!(pull_request_comment_attributes(replies))
              push_reference(project, note, :author_id, comment.author_username)
            end
          rescue StandardError => e
            Gitlab::ErrorTracking.log_exception(
              e,
              import_stage: 'import_standalone_pr_comments',
              merge_request_id: merge_request.id,
              comment_id: comment.id,
              error: e.message
            )
          ensure
            log_info(import_stage: 'import_standalone_pr_comments', message: 'finished', iid: merge_request.iid)
          end
        end

        def pull_request_comment_attributes(comment)
          author = author(comment)
          note = ''

          unless author
            author = project.creator_id
            note = "*By #{comment.author_username} (#{comment.author_email})*\n\n"
          end

          comment_note = comment.note

          note +=
            # Provide some context for replying
            if comment.parent_comment
              parent_comment_note = comment.parent_comment.note.truncate(80, omission: ' ...')

              "> #{parent_comment_note}\n\n#{comment_note}"
            else
              comment_note
            end

          {
            project: project,
            note: wrap_mentions_in_backticks(note),
            author_id: author,
            created_at: comment.created_at,
            updated_at: comment.updated_at,
            imported_from: ::Import::SOURCE_BITBUCKET_SERVER
          }
        end

        def author(comment)
          if user_mapping_enabled?(project)
            user_finder.uid(
              username: comment.author_username,
              display_name: comment.author_name
            )
          else
            user_finder.uid(comment)
          end
        end

        def client
          BitbucketServer::Client.new(project.import_data.credentials)
        end

        def project_key
          project.import_data.data['project_key']
        end

        def repository_slug
          project.import_data.data['repo_slug']
        end
      end
    end
  end
end
