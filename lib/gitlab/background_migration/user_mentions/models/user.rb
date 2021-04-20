# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        # isolated Namespace model
        class User < ActiveRecord::Base
          include Concerns::IsolatedFeatureGate

          self.table_name = 'users'
          self.inheritance_column = :_type_disabled

          has_many :project_authorizations, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

          def authorizations_for_projects(min_access_level: nil, related_project_column: 'projects.id')
            authorizations = project_authorizations
                               .select(1)
                               .where("project_authorizations.project_id = #{related_project_column}")

            return authorizations unless min_access_level.present?

            authorizations.where('project_authorizations.access_level >= ?', min_access_level)
          end

          def can_read_all_resources?
            can?(:read_all_resources)
          end

          def can?(action, subject = :global)
            Ability.allowed?(self, action, subject)
          end
        end
      end
    end
  end
end
