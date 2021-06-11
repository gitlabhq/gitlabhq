# frozen_string_literal: true

module API
  module Entities
    class BasicProjectDetails < Entities::ProjectIdentity
      include ::API::ProjectsRelationBuilder
      include Gitlab::Utils::StrongMemoize

      expose :default_branch, if: -> (project, options) { Ability.allowed?(options[:current_user], :download_code, project) }
      # Avoids an N+1 query: https://github.com/mbleigh/acts-as-taggable-on/issues/91#issuecomment-168273770

      expose :topic_names, as: :tag_list
      expose :topic_names, as: :topics

      expose :ssh_url_to_repo, :http_url_to_repo, :web_url, :readme_url

      expose :license_url, if: :license do |project|
        license = project.repository.license_blob

        if license
          Gitlab::Routing.url_helpers.project_blob_url(project, File.join(project.default_branch, license.path))
        end
      end

      expose :license, with: 'API::Entities::LicenseBasic', if: :license do |project|
        project.repository.license
      end

      expose :avatar_url do |project, options|
        project.avatar_url(only_path: false)
      end

      expose :forks_count
      expose :star_count
      expose :last_activity_at
      expose :namespace, using: 'API::Entities::NamespaceBasic'
      expose :custom_attributes, using: 'API::Entities::CustomAttribute', if: :with_custom_attributes

      # rubocop: disable CodeReuse/ActiveRecord
      def self.preload_relation(projects_relation, options = {})
        # Preloading topics, should be done with using only `:topics`,
        # as `:topics` are defined as: `has_many :topics, through: :taggings`
        # N+1 is solved then by using `subject.topics.map(&:name)`
        # MR describing the solution: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20555
        projects_relation.preload(:project_feature, :route)
                         .preload(:import_state, :topics)
                         .preload(:auto_devops)
                         .preload(namespace: [:route, :owner])
      end
      # rubocop: enable CodeReuse/ActiveRecord

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
    end
  end
end
