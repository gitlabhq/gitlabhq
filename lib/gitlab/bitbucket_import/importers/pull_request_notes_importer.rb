# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class PullRequestNotesImporter
        include ParallelScheduling

        def initialize(project, hash)
          @project = project
          @formatter = Gitlab::ImportFormatter.new
          @user_finder = UserFinder.new(project)
          @ref_converter = Gitlab::BitbucketImport::RefConverter.new(project)
          @mentions_converter = Gitlab::Import::MentionsConverter.new('bitbucket', project)
          @object = hash.with_indifferent_access
          @position_map = {}
          @discussion_map = {}
        end

        def execute
          log_info(import_stage: 'import_pull_request_notes', message: 'starting', iid: object[:iid])

          import_pull_request_comments if merge_request

          log_info(import_stage: 'import_pull_request_notes', message: 'finished', iid: object[:iid])
        rescue StandardError => e
          track_import_failure!(project, exception: e)
        end

        private

        attr_reader :object, :project, :formatter, :user_finder, :ref_converter, :mentions_converter,
          :discussion_map, :position_map

        def import_pull_request_comments
          inline_comments, pr_comments = comments.partition(&:inline?)

          import_inline_comments(inline_comments)
          import_standalone_pr_comments(pr_comments)
        end

        def import_inline_comments(inline_comments)
          children, parents = inline_comments.partition(&:has_parent?)

          parents.each do |comment|
            position_map[comment.iid] = build_position(comment)

            import_comment(comment)
          end

          children.each do |comment|
            position_map[comment.iid] = position_map.fetch(comment.parent_id, nil)

            import_comment(comment)
          end
        end

        def import_comment(comment)
          position = position_map[comment.iid]
          discussion_id = discussion_map[comment.parent_id]

          note = create_diff_note(comment, position, discussion_id)

          discussion_map[comment.iid] = note&.discussion_id
        end

        def create_diff_note(comment, position, discussion_id)
          attributes = pull_request_comment_attributes(comment)
          attributes.merge!(position: position, type: 'DiffNote', discussion_id: discussion_id)

          note = merge_request.notes.build(attributes)

          return note if note.save

          # Bitbucket supports the ability to comment on any line, not just the
          # line in the diff. If we can't add the note as a DiffNote, fallback to creating
          # a regular note.

          log_info(import_stage: 'create_diff_note', message: 'creating fallback DiffNote', iid: merge_request.iid)
          create_fallback_diff_note(comment, position)
        rescue StandardError => e
          Gitlab::ErrorTracking.log_exception(
            e,
            import_stage: 'create_diff_note', comment_id: comment.iid, error: e.message
          )

          nil
        end

        def create_fallback_diff_note(comment, position)
          attributes = pull_request_comment_attributes(comment)
          note = "*Comment on"

          note += " #{position.old_path}:#{position.old_line} -->" if position&.old_line
          note += " #{position.new_path}:#{position.new_line}" if position&.new_line
          note += "*\n\n#{comment.note}"

          attributes[:note] = note
          merge_request.notes.create!(attributes)
        end

        def build_position(pr_comment)
          params = {
            diff_refs: merge_request.diff_refs,
            old_path: pr_comment.file_path,
            new_path: pr_comment.file_path,
            old_line: pr_comment.old_pos,
            new_line: pr_comment.new_pos
          }

          Gitlab::Diff::Position.new(params)
        end

        def import_standalone_pr_comments(pr_comments)
          pr_comments.each do |comment|
            attributes = pull_request_comment_attributes(comment)
            merge_request.notes.create!(attributes)
          end
        end

        def pull_request_comment_attributes(comment)
          {
            project: project,
            author_id: user_finder.gitlab_user_id(project, comment.author),
            note: comment_note(comment),
            created_at: comment.created_at,
            updated_at: comment.updated_at,
            imported_from: ::Import::SOURCE_BITBUCKET
          }
        end

        def comment_note(comment)
          author = formatter.author_line(comment.author_nickname) unless user_finder.find_user_id(comment.author)
          note = author.to_s + ref_converter.convert_note(comment.note.to_s)
          mentions_converter.convert(note)
        end

        def merge_request
          @merge_request ||= project.merge_requests.iid_in(object[:iid]).first
        end

        def comments
          client.pull_request_comments(project.import_source, merge_request.iid).reject(&:deleted?)
        end
      end
    end
  end
end
