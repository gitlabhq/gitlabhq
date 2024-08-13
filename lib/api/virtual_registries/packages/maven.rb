# frozen_string_literal: true

module API
  module VirtualRegistries
    module Packages
      class Maven < ::API::Base
        include ::API::Concerns::VirtualRegistries::Packages::Endpoint

        authenticate_with do |accept|
          accept.token_types(:personal_access_token).sent_through(:http_private_token_header)
          accept.token_types(:deploy_token).sent_through(:http_deploy_token_header)
          accept.token_types(:job_token).sent_through(:http_job_token_header)

          accept.token_types(
            :personal_access_token_with_username,
            :deploy_token_with_username,
            :job_token_with_username
          ).sent_through(:http_basic_auth)
        end

        helpers do
          include ::Gitlab::Utils::StrongMemoize

          def registry
            ::VirtualRegistries::Packages::Maven::Registry.find(declared_params[:id])
          end
          strong_memoize_attr :registry
        end

        desc 'Download endpoint of the Maven virtual registry.' do
          detail 'This feature was introduced in GitLab 17.3. \
                  This feature is currently in experiment state. \
                  This feature behind the `virtual_registry_maven` feature flag.'
          success [
            { code: 200 }
          ]
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[maven_virtual_registries]
          hidden true
        end
        params do
          requires :id,
            type: Integer,
            desc: 'The ID of the Maven virtual registry'
          requires :path,
            type: String,
            file_path: true,
            desc: 'Package path',
            documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar' }
        end
        get 'virtual_registries/packages/maven/:id/*path', format: false do
          service_response = ::VirtualRegistries::Packages::Maven::HandleFileRequestService.new(
            registry: registry,
            current_user: current_user,
            params: { path: declared_params[:path] }
          ).execute

          send_error_response_from!(service_response: service_response) if service_response.error?
          send_successful_response_from(service_response: service_response)
        end
      end
    end
  end
end
