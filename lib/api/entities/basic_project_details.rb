# frozen_string_literal: true

module API
  module Entities
    class BasicProjectDetails < Entities::ProjectIdentity
      include ::API::ProjectsRelationBuilder
      include Gitlab::Utils::StrongMemoize

      expose :default_branch_or_main, documentation: { type: 'string', example: 'main' }, as: :default_branch, if: ->(project, options) { Ability.allowed?(options[:current_user], :read_code, project) }
      # Avoids an N+1 query: https://github.com/mbleigh/acts-as-taggable-on/issues/91#issuecomment-168273770

      expose :topic_names, as: :tag_list, documentation: { type: 'string', is_array: true, example: 'tag' }
      expose :topic_names, as: :topics, documentation: { type: 'string', is_array: true, example: 'topic' }

      expose :ssh_url_to_repo, documentation: { type: 'string', example: 'git@gitlab.example.com:gitlab/gitlab.git' }
      expose :http_url_to_repo, documentation: { type: 'string', example: 'https://gitlab.example.com/gitlab/gitlab.git' }
      expose :web_url, documentation: { type: 'string', example: 'https://gitlab.example.com/gitlab/gitlab' }
      with_options if: ->(_, _) { user_has_access_to_project_repository? } do
        expose :readme_url, documentation: { type: 'string', example: 'https://gitlab.example.com/gitlab/gitlab/blob/master/README.md' }
        expose :forks_count, documentation: { type: 'integer', example: 1 }
      end

      expose :license_url, if: :license, documentation: { type: 'string', example: 'https://gitlab.example.com/gitlab/gitlab/blob/master/LICENCE' } do |project|
        license = project.repository.license_blob

        if license
          Gitlab::Routing.url_helpers.project_blob_url(project, File.join(project.default_branch, license.path))
        end
      end

      expose :license, with: 'API::Entities::LicenseBasic', if: :license do |project|
        project.repository.license
      end

      expose :avatar_url, documentation: { type: 'string', example: 'http://example.com/uploads/project/avatar/3/uploads/avatar.png' } do |project, options|
        project.avatar_url(only_path: false)
      end

      expose :star_count, documentation: { type: 'integer', example: 1 }
      expose :last_activity_at, documentation: { type: 'dateTime', example: '2013-09-30T13:46:02Z' }
      expose :namespace, using: 'API::Entities::NamespaceBasic'
      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes

      expose :repository_storage, documentation: { type: 'string', example: 'default' }, if: ->(project, options) {
        Ability.allowed?(options[:current_user], :change_repository_storage, project)
      }

      # rubocop: disable CodeReuse/ActiveRecord
      def self.preload_relation(projects_relation, options = {})
        # Preloading topics, should be done with using only `:topics`,
        # as `:topics` are defined as: `has_many :topics, through: :project_topics`
        # N+1 is solved then by using `subject.topics.map(&:name)`
        # MR describing the solution: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20555
        projects_relation.preload(:project_feature, :route)
                         .preload(:import_state, :topics)
                         .preload(:auto_devops)
                         .preload(namespace: [:route, :owner])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.execute_batch_counting(projects_relation)
        # Call the count methods on every project, so the BatchLoader would load them all at
        # once when the entities are rendered
        projects_relation.each(&:forks_count)

        super
      end

      def self.postload_relation(projects_relation, options = {}) end

      private

      alias_method :project, :object

      def topic_names
        # Topics is a preloaded association. If we perform then sorting
        # through the database, it will trigger a new query, ending up
        # in an N+1 if we have several projects
        strong_memoize(:topic_names) do
          project.topics.pluck(:name).sort # rubocop:disable CodeReuse/ActiveRecord
        end
      end

      def user_has_access_to_project_repository?
        Ability.allowed?(options[:current_user], :read_code, project)
      end
    end
  end
end
