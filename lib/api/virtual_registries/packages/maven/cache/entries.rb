# frozen_string_literal: true

module API
  module VirtualRegistries
    module Packages
      module Maven
        module Cache
          class Entries < ::API::Base
            include ::API::Helpers::Authentication
            include ::API::PaginationParams

            feature_category :virtual_registry
            urgency :low

            authenticate_with do |accept|
              accept.token_types(:personal_access_token).sent_through(:http_private_token_header)
              accept.token_types(:deploy_token).sent_through(:http_deploy_token_header)
              accept.token_types(:job_token).sent_through(:http_job_token_header)
            end

            helpers do
              include ::Gitlab::Utils::StrongMemoize

              def require_dependency_proxy_enabled!
                not_found! unless ::Gitlab.config.dependency_proxy.enabled
              end

              def upstream
                ::VirtualRegistries::Packages::Maven::Upstream.find(params[:id])
              end
              strong_memoize_attr :upstream

              def cache_entries
                upstream.default_cache_entries.order_created_desc.search_by_relative_path(params[:search])
              end

              def cache_entry
                ::VirtualRegistries::Packages::Maven::Cache::Entry
                  .default
                  .find_by_upstream_id_and_relative_path!(*declared_params[:id].split)
              end
              strong_memoize_attr :cache_entry
            end

            after_validation do
              not_found! unless Feature.enabled?(:virtual_registry_maven, current_user)

              require_dependency_proxy_enabled!

              authenticate!
            end

            namespace 'virtual_registries/packages/maven' do
              namespace :upstreams do
                route_param :id, type: Integer, desc: 'The ID of the maven virtual registry upstream' do
                  namespace :cache_entries do
                    desc 'List maven virtual registry upstream cache entries' do
                      detail 'This feature was introduced in GitLab 17.4. \
                            This feature is currently in an experimental state. \
                            This feature is behind the `virtual_registry_maven` feature flag.'
                      success ::API::Entities::VirtualRegistries::Packages::Maven::Cache::Entry
                      failure [
                        { code: 400, message: 'Bad Request' },
                        { code: 401, message: 'Unauthorized' },
                        { code: 403, message: 'Forbidden' },
                        { code: 404, message: 'Not found' }
                      ]
                      tags %w[maven_virtual_registries]
                      is_array true
                      hidden true
                    end

                    params do
                      optional :search, type: String, desc: 'Search query', documentation: { example: 'foo/bar/mypkg' }
                      use :pagination
                    end
                    get do
                      authorize! :read_virtual_registry, upstream

                      present paginate(cache_entries),
                        with: ::API::Entities::VirtualRegistries::Packages::Maven::Cache::Entry
                    end
                  end
                end
              end

              namespace :cache_entries do
                desc 'Delete a maven virtual registry upstream cache entry' do
                  detail 'This feature was introduced in GitLab 17.4. \
                          This feature is currently in an experimental state. \
                          This feature is behind the `virtual_registry_maven` feature flag.'
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
                params do
                  requires :id, type: String, coerce_with: Base64.method(:urlsafe_decode64),
                    desc: 'The base64 encoded upstream id and relative path of the cache entry',
                    documentation: { example: 'Zm9vL2Jhci9teXBrZy5wb20=' }
                end

                delete '*id' do
                  authorize! :destroy_virtual_registry, cache_entry.upstream

                  destroy_conditionally!(cache_entry) do |cache_entry|
                    render_validation_error!(cache_entry) unless cache_entry.mark_as_pending_destruction
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
