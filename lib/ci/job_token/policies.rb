# frozen_string_literal: true

module Ci
  module JobToken
    module Policies
      # policies that every CI job token needs
      FIXED = [
        :build_create_container_image,
        :build_destroy_container_image,
        :build_download_code,
        :build_push_code,
        :build_read_container_image,
        :read_project
      ].freeze

      # policies that can be assigned to a CI job token
      ALLOWED = [
        :admin_container_image,
        :admin_secure_files,
        :admin_terraform_state,
        :create_deployment,
        :create_environment,
        :create_on_demand_dast_scan,
        :create_package,
        :create_release,
        :destroy_container_image,
        :destroy_deployment,
        :destroy_environment,
        :destroy_package,
        :destroy_release,
        :read_build,
        :read_container_image,
        :read_deployment,
        :read_environment,
        :read_group,
        :read_job_artifacts,
        :read_package,
        :read_pipeline,
        :read_release,
        :read_secure_files,
        :read_terraform_state,
        :stop_environment,
        :update_deployment,
        :update_environment,
        :update_pipeline,
        :update_release
      ].freeze
    end
  end
end
