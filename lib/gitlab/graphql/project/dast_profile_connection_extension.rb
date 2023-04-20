# frozen_string_literal: true
module Gitlab
  module Graphql
    module Project
      class DastProfileConnectionExtension < GraphQL::Schema::FieldExtension
        def after_resolve(value:, object:, context:, **rest)
          preload_authorizations(context[:project_dast_profiles])
          context[:project_dast_profiles] = nil
          value
        end

        def preload_authorizations(dast_profiles)
          return unless dast_profiles

          project_users = dast_profiles.group_by(&:project).transform_values do |project_profiles|
            project_profiles
              .filter_map { |profile| profile.dast_profile_schedule&.owner }
              .uniq
          end
          Preloaders::UsersMaxAccessLevelByProjectPreloader.new(project_users: project_users).execute
        end
      end
    end
  end
end
