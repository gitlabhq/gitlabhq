# frozen_string_literal: true

module Ci
  module JobToken
    module Policies
      POLICIES_BY_CATEGORY = [
        {
          value: :containers,
          text: 'Containers',
          description: 'Containers category',
          policies: [
            {
              value: :read_containers,
              type: :read,
              text: 'Read',
              description: 'Read container images in a project'
            },
            {
              value: :admin_containers,
              type: :admin,
              text: 'Read and write',
              description: 'Admin container images in a project'
            }
          ]
        },
        {
          value: :deployments,
          text: 'Deployments',
          description: 'Deployments category',
          policies: [
            { value: :read_deployments, type: :read, text: 'Read', description: 'Read deployments in a project' },
            {
              value: :admin_deployments,
              type: :admin,
              text: 'Read and write',
              description: 'Admin deployments in a project'
            }
          ]
        },
        {
          value: :environments,
          text: 'Environments',
          description: 'Environments category',
          policies: [
            { value: :read_environments, type: :read, text: 'Read', description: 'Read environments in a project' },
            {
              value: :admin_environments,
              type: :admin,
              text: 'Read and write',
              description: 'Admin + Stop environments in a project'
            }
          ]
        },
        {
          value: :jobs,
          text: 'Jobs',
          description: 'Jobs category',
          policies: [
            { value: :read_jobs, type: :read, text: 'Read', description: 'Read job metadata and artifacts' },
            {
              value: :admin_jobs,
              type: :admin,
              text: 'Read and write',
              description: 'Read job metadata, upload artifacts and update the pipeline status'
            }
          ]
        },
        {
          value: :packages,
          text: 'Packages',
          description: 'Packages category',
          policies: [
            { value: :read_packages, type: :read, text: 'Read', description: 'Read packages' },
            { value: :admin_packages, type: :admin, text: 'Read and write', description: 'Admin packages' }
          ]
        },
        {
          value: :releases,
          text: 'Releases',
          description: 'Releases category',
          policies: [
            { value: :read_releases, type: :read, text: 'Read', description: 'Read releases in a project' },
            { value: :admin_releases, type: :admin, text: 'Read and write', description: 'Admin releases in a project' }
          ]
        },
        {
          value: :secure_files,
          text: 'Secure files',
          description: 'Secure files category',
          policies: [
            { value: :read_secure_files, type: :read, text: 'Read', description: 'Read secure files in a project' },
            {
              value: :admin_secure_files,
              type: :admin,
              text: 'Read and write',
              description: 'Admin secure files in a project'
            }
          ]
        },
        {
          value: :terraform_state,
          text: 'Terraform state',
          description: 'Terraform state category',
          policies: [
            {
              value: :read_terraform_state,
              type: :read,
              text: 'Read',
              description: 'Read terraform state files/version'
            },
            {
              value: :admin_terraform_state,
              type: :admin,
              text: 'Read and write',
              description: 'Admin terraform state files/versions'
            }
          ]
        }
      ].freeze

      class << self
        def all_policies
          POLICIES_BY_CATEGORY.flat_map { |category| category[:policies] }
        end
      end
    end
  end
end
