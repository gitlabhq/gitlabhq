# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        # isolated Namespace model
        class Project < ActiveRecord::Base
          include Concerns::IsolatedFeatureGate
          include Gitlab::BackgroundMigration::UserMentions::Lib::Gitlab::IsolatedVisibilityLevel

          self.table_name = 'projects'
          self.inheritance_column = :_type_disabled

          belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'namespace_id', class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::Group"
          belongs_to :namespace, class_name: "::Gitlab::BackgroundMigration::UserMentions::Models::Namespace"
          alias_method :parent, :namespace

          # Returns a collection of projects that is either public or visible to the
          # logged in user.
          def self.public_or_visible_to_user(user = nil, min_access_level = nil)
            min_access_level = nil if user&.can_read_all_resources?

            return public_to_user unless user

            if user.is_a?(::Gitlab::BackgroundMigration::UserMentions::Models::User)
              where('EXISTS (?) OR projects.visibility_level IN (?)',
                    user.authorizations_for_projects(min_access_level: min_access_level),
                    levels_for_user(user))
            end
          end

          def grafana_integration
            nil
          end

          def default_issues_tracker?
            true # we do not care of the issue tracker type(internal or external) when parsing mentions
          end

          def visibility_level_field
            :visibility_level
          end
        end
      end
    end
  end
end
