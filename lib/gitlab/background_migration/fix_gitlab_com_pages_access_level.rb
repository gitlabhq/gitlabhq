# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Fixes https://gitlab.com/gitlab-org/gitlab/issues/32961
    class FixGitlabComPagesAccessLevel
      # Copy routable here to avoid relying on application logic
      module Routable
        def build_full_path
          if parent && path
            parent.build_full_path + '/' + path
          else
            path
          end
        end
      end

      # Namespace
      class Namespace < ActiveRecord::Base
        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled

        include Routable

        belongs_to :parent, class_name: "Namespace"
      end

      # ProjectPagesMetadatum
      class ProjectPagesMetadatum < ActiveRecord::Base
        self.primary_key = :project_id

        belongs_to :project, inverse_of: :pages_metadatum

        scope :deployed, -> { where(deployed: true) }
      end

      # Project
      class Project < ActiveRecord::Base
        self.table_name = 'projects'
        self.inheritance_column = :_type_disabled

        include Routable

        belongs_to :namespace
        alias_method :parent, :namespace
        alias_attribute :parent_id, :namespace_id

        has_one :project_feature, inverse_of: :project

        has_one :pages_metadatum, class_name: 'ProjectPagesMetadatum', inverse_of: :project

        scope :with_pages_deployed, -> do
          joins(:pages_metadatum).merge(ProjectPagesMetadatum.deployed)
        end

        PRIVATE = 0
        INTERNAL = 10
        PUBLIC = 20

        delegate :public_pages?, to: :project_feature

        def public_pages_path
          File.join(pages_path, 'public')
        end

        def pages_path
          File.join(Settings.pages.path, build_full_path)
        end

        def public?
          visibility_level == PUBLIC
        end
      end

      # ProjectFeature
      class ProjectFeature < ActiveRecord::Base
        self.table_name = 'project_features'

        belongs_to :project

        DISABLED = 0
        PRIVATE  = 10
        ENABLED  = 20
        PUBLIC   = 30
      end

      def perform(start_id, stop_id)
        logger = Gitlab::BackgroundMigration::Logger.build

        Project.where(id: start_id..stop_id).with_pages_deployed.includes(:project_feature).find_each do |project|
          config_path = File.join(project.pages_path, 'config.json')
          ac_is_enabled_in_config = JSON.parse(File.read(config_path))["access_control"]

          next if ac_is_enabled_in_config # we already made site private and don't want to surprise the user

          next if project.project_feature.pages_access_level == ProjectFeature::DISABLED

          new_access_level = project.public? ? ProjectFeature::ENABLED : ProjectFeature::PUBLIC

          next if project.project_feature.pages_access_level == new_access_level

          logger.info(
            message: "Changing pages access control level",
            project_id: project.id,
            access_level_before: project.project_feature.pages_access_level,
            access_level_after: new_access_level
          )

          project.project_feature.update_column(:pages_access_level, new_access_level)
        rescue => e
          Gitlab::Sentry.track_exception(e, extra: { project_id: project.id })
        end
      end
    end
  end
end
