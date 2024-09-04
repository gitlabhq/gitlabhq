# frozen_string_literal: true

module API
  module VirtualRegistries
    module Packages
      class Maven < ::API::Base
        include ::API::Helpers::Authentication

        feature_category :virtual_registry
        urgency :low

        MAX_FILE_SIZE = 5.gigabytes

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

          params :id_and_path do
            requires :id,
              type: Integer,
              desc: 'The ID of the Maven virtual registry'
            requires :path,
              type: String,
              file_path: true,
              desc: 'Package path',
              documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar' }
          end
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

          namespace ':id/*path' do
            include ::API::Concerns::VirtualRegistries::Packages::Endpoint

            desc 'Download endpoint of the Maven virtual registry.' do
              detail 'This feature was introduced in GitLab 17.3. \
                      This feature is currently in experiment state. \
                      This feature is behind the `virtual_registry_maven` feature flag.'
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
              use :id_and_path
            end
            get format: false do
              service_response = ::VirtualRegistries::Packages::Maven::HandleFileRequestService.new(
                registry: registry,
                current_user: current_user,
                params: { path: declared_params[:path] }
              ).execute

              send_error_response_from!(service_response: service_response) if service_response.error?
              send_successful_response_from(service_response: service_response)
            end

            namespace 'upload' do
              after_validation do
                require_gitlab_workhorse!
                authorize!(:read_virtual_registry, registry)
              end

              desc 'Workhorse authorize upload endpoint of the Maven virtual registry. Only workhorse can access it.' do
                detail 'This feature was introduced in GitLab 17.4. \
                        This feature is currently in experiment state. \
                        This feature is behind the `virtual_registry_maven` feature flag.'
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
                use :id_and_path
              end
              post 'authorize' do
                status 200
                content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
                ::VirtualRegistries::CachedResponseUploader.workhorse_authorize(has_length: true,
                  maximum_size: MAX_FILE_SIZE)
              end

              desc 'Workhorse upload endpoint of the Maven virtual registry. Only workhorse can access it.' do
                detail 'This feature was introduced in GitLab 17.4. \
                        This feature is currently in experiment state. \
                        This feature is behind the `virtual_registry_maven` feature flag.'
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
                use :id_and_path
                requires :file,
                  type: ::API::Validations::Types::WorkhorseFile,
                  desc: 'The file being uploaded',
                  documentation: { type: 'file' }
              end
              post do
                etag, content_type, upstream_gid = request.headers.fetch_values(
                  'Etag',
                  ::Gitlab::Workhorse::SEND_DEPENDENCY_CONTENT_TYPE_HEADER,
                  UPSTREAM_GID_HEADER
                ) { nil }

                # TODO: revisit this part when multiple upstreams are supported
                # https://gitlab.com/gitlab-org/gitlab/-/issues/480461
                # coherence check
                not_found!('Upstream') unless upstream == GlobalID::Locator.locate(upstream_gid)

                service_response = ::VirtualRegistries::Packages::Maven::CachedResponses::CreateService.new(
                  upstream: upstream,
                  current_user: current_user,
                  params: declared_params.merge(etag: etag, content_type: content_type)
                ).execute

                send_error_response_from!(service_response: service_response) if service_response.error?
                created!
              end
            end
          end
        end
      end
    end
  end
end
