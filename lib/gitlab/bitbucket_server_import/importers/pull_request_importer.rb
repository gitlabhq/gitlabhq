# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class PullRequestImporter
        include Loggable

        def initialize(project, hash)
          @project = project
          @formatter = Gitlab::ImportFormatter.new
          @user_finder = UserFinder.new(project)
          @mentions_converter = Gitlab::Import::MentionsConverter.new('bitbucket_server', project)

          # Object should behave as a object so we can remove object.is_a?(Hash) check
          # This will be fixed in https://gitlab.com/gitlab-org/gitlab/-/issues/412328
          @object = hash.with_indifferent_access
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
            author_id: user_finder.author_id(object),
            created_at: object[:created_at],
            updated_at: object[:updated_at]
          }

          creator = Gitlab::Import::MergeRequestCreator.new(project)

          creator.execute(attributes)

          log_info(import_stage: 'import_pull_request', message: 'finished', iid: object[:iid])
        end

        private

        attr_reader :object, :project, :formatter, :user_finder, :mentions_converter

        def description
          description = ''
          description += author_line
          description += object[:description] if object[:description]

          if Feature.enabled?(:bitbucket_server_convert_mentions_to_users, project.creator)
            description = mentions_converter.convert(description)
          end

          description
        end

        def author_line
          return '' if user_finder.uid(object)

          formatter.author_line(object[:author])
        end

        def reviewers
          return [] unless object[:reviewers].present?

          object[:reviewers].filter_map do |reviewer|
            if Feature.enabled?(:bitbucket_server_user_mapping_by_username, type: :ops)
              user_finder.find_user_id(by: :username, value: reviewer.dig('user', 'slug'))
            else
              user_finder.find_user_id(by: :email, value: reviewer.dig('user', 'emailAddress'))
            end
          end
        end

        def source_branch_sha
          source_branch_sha = project.repository.commit(object[:source_branch_sha])&.sha

          return source_branch_sha if source_branch_sha

          project.repository.find_commits_by_message(object[:source_branch_sha])&.first&.sha
        end
      end
    end
  end
end
