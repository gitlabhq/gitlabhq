# frozen_string_literal: true

module API
  module VirtualRegistries
    module Packages
      class Maven < ::API::Base
        include ::API::Helpers::Authentication

        feature_category :virtual_registry
        urgency :low

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

          delegate :group, :upstream, :registry_upstream, to: :registry

          def require_dependency_proxy_enabled!
            not_found! unless ::Gitlab.config.dependency_proxy.enabled
          end

          def registry
            ::VirtualRegistries::Packages::Maven::Registry.find(params[:id])
          end
          strong_memoize_attr :registry
        end

        after_validation do
          not_found! unless Feature.enabled?(:virtual_registry_maven, current_user)

          require_dependency_proxy_enabled!

          authenticate!
        end

        namespace 'virtual_registries/packages/maven' do
          namespace :registries do
            include ::API::Concerns::VirtualRegistries::Packages::Maven::RegistryEndpoints

            route_param :id, type: Integer, desc: 'The ID of the maven virtual registry' do
              namespace :upstreams do
                include ::API::Concerns::VirtualRegistries::Packages::Maven::UpstreamEndpoints

                route_param :upstream_id, type: Integer, desc: 'The ID of the maven virtual registry upstream' do
                  namespace :cached_responses do
                    include ::API::Concerns::VirtualRegistries::Packages::Maven::CachedResponseEndpoints
                  end
                end
              end
            end
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
          namespace ':id/*path' do
            include ::API::Concerns::VirtualRegistries::Packages::Endpoint

            get format: false do
              service_response = ::VirtualRegistries::Packages::Maven::HandleFileRequestService.new(
                registry: registry,
                current_user: current_user,
                params: { path: params[:path] }
              ).execute

              send_error_response_from!(service_response: service_response) if service_response.error?
              send_successful_response_from(service_response: service_response)
            end
          end
        end
      end
    end
  end
end
