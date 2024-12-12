# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class PullRequestImporter
        include Loggable
        include Gitlab::Import::UsernameMentionRewriter
        include ::Import::PlaceholderReferences::Pusher

        def initialize(project, hash)
          @project = project
          @formatter = Gitlab::ImportFormatter.new
          @user_finder = UserFinder.new(project)
          # Object should behave as a object so we can remove object.is_a?(Hash) check
          # This will be fixed in https://gitlab.com/gitlab-org/gitlab/-/issues/412328
          @object = hash.with_indifferent_access

          @reviewer_references = {}
        end

        def execute
          log_info(import_stage: 'import_pull_request', message: 'starting', iid: object[:iid])

          attributes = {
            iid: object[:iid],
            title: object[:title],
            description: description,
            reviewer_ids: reviewers,
            source_project_id: project.id,
            source_branch: Gitlab::Git.ref_name(object[:source_branch_name]),
            source_branch_sha: source_branch_sha,
            target_project_id: project.id,
            target_branch: Gitlab::Git.ref_name(object[:target_branch_name]),
            target_branch_sha: object[:target_branch_sha],
            state_id: MergeRequest.available_states[object[:state]],
            author_id: author_id(object),
            created_at: object[:created_at],
            updated_at: object[:updated_at],
            imported_from: ::Import::HasImportSource::IMPORT_SOURCES[:bitbucket_server]
          }

          creator = Gitlab::Import::MergeRequestCreator.new(project)

          merge_request = creator.execute(attributes)
          push_reference(project, merge_request, :author_id, object[:author_username])
          push_reviewer_references(merge_request)

          # Create refs/merge-requests/iid/head reference for the merge request
          merge_request.fetch_ref!

          log_info(import_stage: 'import_pull_request', message: 'finished', iid: object[:iid])
        end

        private

        attr_reader :object, :project, :formatter, :user_finder

        def description
          description = ''
          description += author_line
          description += object[:description] if object[:description]

          wrap_mentions_in_backticks(description)
        end

        def author_line
          return '' if user_mapping_enabled?(project) || user_finder.uid(object)

          formatter.author_line(object[:author])
        end

        def author_id(pull_request_data)
          if user_mapping_enabled?(project)
            user_finder.author_id(
              username: pull_request_data['author_username'],
              display_name: pull_request_data['author']
            )
          else
            user_finder.author_id(pull_request_data)
          end
        end

        def reviewers
          return [] unless object[:reviewers].present?

          object[:reviewers].filter_map do |reviewer_data|
            if user_mapping_enabled?(project)
              uid = user_finder.uid(
                username: reviewer_data.dig('user', 'slug'),
                display_name: reviewer_data.dig('user', 'displayName')
              )

              @reviewer_references[uid] = reviewer_data.dig('user', 'slug')

              uid
            else
              user_finder.find_user_id(by: :email, value: reviewer_data.dig('user', 'emailAddress'))
            end
          end
        end

        def source_branch_sha
          source_branch_sha = project.repository.commit(object[:source_branch_sha])&.sha

          return source_branch_sha if source_branch_sha

          project.repository.find_commits_by_message(object[:source_branch_sha])&.first&.sha
        end

        def push_reviewer_references(merge_request)
          mr_reviewers = merge_request.merge_request_reviewers
          mr_reviewers.each do |mr_reviewer|
            push_reference(project, mr_reviewer, :user_id, @reviewer_references[mr_reviewer.user_id])
          end
        end
      end
    end
  end
end
