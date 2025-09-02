# frozen_string_literal: true

module Ci
  module JobToken
    module Policies
      POLICIES = [
        :read_deployments,
        :admin_deployments,
        :read_environments,
        :admin_environments,
        :read_jobs,
        :admin_jobs,
        :read_merge_requests,
        :read_packages,
        :admin_packages,
        :read_pipelines,
        :admin_pipelines,
        :read_releases,
        :admin_releases,
        :read_repositories,
        :read_secure_files,
        :admin_secure_files,
        :read_terraform_state,
        :admin_terraform_state
      ].freeze

      DEPRECATED_POLICIES = [
        :read_containers,
        :admin_containers
      ].freeze

      class << self
        def all_values
          POLICIES.map(&:to_s)
        end
      end
    end
  end
end
