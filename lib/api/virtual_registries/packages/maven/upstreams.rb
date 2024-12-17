# frozen_string_literal: true

module API
  module VirtualRegistries
    module Packages
      module Maven
        class Upstreams < ::API::Base
          include ::API::Helpers::Authentication

          feature_category :virtual_registry
          urgency :low

          authenticate_with do |accept|
            accept.token_types(:personal_access_token).sent_through(:http_private_token_header)
            accept.token_types(:deploy_token).sent_through(:http_deploy_token_header)
            accept.token_types(:job_token).sent_through(:http_job_token_header)
          end

          helpers do
            include ::Gitlab::Utils::StrongMemoize

            delegate :group, :registry_upstream, to: :registry

            def require_dependency_proxy_enabled!
              not_found! unless Gitlab.config.dependency_proxy.enabled
            end

            def registry
              ::VirtualRegistries::Packages::Maven::Registry.find(params[:id])
            end
            strong_memoize_attr :registry

            def upstream
              ::VirtualRegistries::Packages::Maven::Upstream.find(params[:id])
            end
            strong_memoize_attr :upstream
          end

          after_validation do
            not_found! unless Feature.enabled?(:virtual_registry_maven, current_user)

            require_dependency_proxy_enabled!

            authenticate!
          end

          namespace 'virtual_registries/packages/maven' do
            namespace :registries do
              route_param :id, type: Integer, desc: 'The ID of the maven virtual registry' do
                namespace :upstreams do
                  desc 'List all maven virtual registry upstreams' do
                    detail 'This feature was introduced in GitLab 17.4. \
                        This feature is currently in experiment state. \
                        This feature behind the `virtual_registry_maven` feature flag.'
                    success code: 200
                    failure [
                      { code: 400, message: 'Bad Request' },
                      { code: 401, message: 'Unauthorized' },
                      { code: 403, message: 'Forbidden' },
                      { code: 404, message: 'Not found' }
                    ]
                    tags %w[maven_virtual_registries]
                    hidden true
                  end
                  get do
                    authorize! :read_virtual_registry, registry

                    present [registry.upstream].compact, with: Entities::VirtualRegistries::Packages::Maven::Upstream
                  end

                  desc 'Add a maven virtual registry upstream' do
                    detail 'This feature was introduced in GitLab 17.4. \
                        This feature is currently in experiment state. \
                        This feature behind the `virtual_registry_maven` feature flag.'
                    success code: 201, model: ::API::Entities::VirtualRegistries::Packages::Maven::Upstream
                    failure [
                      { code: 400, message: 'Bad Request' },
                      { code: 401, message: 'Unauthorized' },
                      { code: 403, message: 'Forbidden' },
                      { code: 404, message: 'Not found' },
                      { code: 409, message: 'Conflict' }
                    ]
                    tags %w[maven_virtual_registries]
                    hidden true
                  end
                  params do
                    requires :url, type: String, desc: 'The URL of the maven virtual registry upstream',
                      allow_blank: false
                    optional :username, type: String, desc: 'The username of the maven virtual registry upstream'
                    optional :password, type: String, desc: 'The password of the maven virtual registry upstream'
                    optional :cache_validity_hours, type: Integer, desc: 'The cache validity in hours. Defaults to 24'
                    all_or_none_of :username, :password
                  end
                  post do
                    authorize! :create_virtual_registry, registry

                    conflict!(_('Upstream already exists')) if registry.upstream

                    new_upstream = registry.build_upstream(declared_params(include_missing: false).merge(group:))
                    registry_upstream.group = group

                    ApplicationRecord.transaction do
                      render_validation_error!(new_upstream) unless new_upstream.save
                      render_validation_error!(registry_upstream) unless registry_upstream.save
                    end

                    present new_upstream, with: Entities::VirtualRegistries::Packages::Maven::Upstream
                  end
                end
              end
            end

            namespace :upstreams do
              route_param :id, type: Integer, desc: 'The ID of the maven virtual registry upstream' do
                desc 'Get a specific maven virtual registry upstream' do
                  detail 'This feature was introduced in GitLab 17.4. \
                        This feature is currently in experiment state. \
                        This feature behind the `virtual_registry_maven` feature flag.'
                  success ::API::Entities::VirtualRegistries::Packages::Maven::Upstream
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not found' }
                  ]
                  tags %w[maven_virtual_registries]
                  hidden true
                end
                get do
                  authorize! :read_virtual_registry, upstream

                  present upstream, with: ::API::Entities::VirtualRegistries::Packages::Maven::Upstream
                end

                desc 'Update a maven virtual registry upstream' do
                  detail 'This feature was introduced in GitLab 17.4. \
                        This feature is currently in experiment state. \
                        This feature behind the `virtual_registry_maven` feature flag.'
                  success code: 200
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not found' }
                  ]
                  tags %w[maven_virtual_registries]
                  hidden true
                end
                params do
                  with(allow_blank: false) do
                    optional :url, type: String, desc: 'The URL of the maven virtual registry upstream'
                    optional :username, type: String, desc: 'The username of the maven virtual registry upstream'
                    optional :password, type: String, desc: 'The password of the maven virtual registry upstream'
                    optional :cache_validity_hours, type: Integer, desc: 'The validity of the cache in hours'
                  end

                  at_least_one_of :url, :username, :password, :cache_validity_hours
                end
                patch do
                  authorize! :update_virtual_registry, upstream

                  render_validation_error!(upstream) unless upstream.update(declared_params(include_missing: false))

                  status :ok
                end

                desc 'Delete a maven virtual registry upstream' do
                  detail 'This feature was introduced in GitLab 17.4. \
                        This feature is currently in experiment state. \
                        This feature behind the `virtual_registry_maven` feature flag.'
                  success code: 204
                  failure [
                    { code: 400, message: 'Bad Request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not found' }
                  ]
                  tags %w[maven_virtual_registries]
                  hidden true
                end
                delete do
                  authorize! :destroy_virtual_registry, upstream

                  destroy_conditionally!(upstream)
                end
              end
            end
          end
        end
      end
    end
  end
end
