# frozen_string_literal: true
module Gitlab
  module Graphql
    module Project
      class DastProfileConnectionExtension < GraphQL::Schema::Field::ConnectionExtension
        def after_resolve(value:, object:, context:, **rest)
          preload_authorizations(context[:project_dast_profiles])
          context[:project_dast_profiles] = nil
          value
        end

        def preload_authorizations(dast_profiles)
          return unless dast_profiles

          projects = dast_profiles.map(&:project)
          users = dast_profiles.filter_map { |dast_profile| dast_profile.dast_profile_schedule&.owner }
          Preloaders::UsersMaxAccessLevelInProjectsPreloader.new(projects: projects, users: users).execute
        end
      end
    end
  end
end
