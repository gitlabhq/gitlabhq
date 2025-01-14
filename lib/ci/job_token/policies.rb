# frozen_string_literal: true

module Ci
  module JobToken
    module Policies
      POLICIES = [
        :read_containers,
        :admin_containers,
        :read_deployments,
        :admin_deployments,
        :read_environments,
        :admin_environments,
        :read_jobs,
        :admin_jobs,
        :read_packages,
        :admin_packages,
        :read_releases,
        :admin_releases,
        :read_secure_files,
        :admin_secure_files,
        :read_terraform_state,
        :admin_terraform_state
      ].freeze

      class << self
        def all_values
          POLICIES.map(&:to_s)
        end
      end
    end
  end
end
