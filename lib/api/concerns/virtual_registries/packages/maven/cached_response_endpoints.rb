# frozen_string_literal: true

module API
  module Concerns
    module VirtualRegistries
      module Packages
        module Maven
          module CachedResponseEndpoints
            extend ActiveSupport::Concern

            included do
              include ::API::PaginationParams

              helpers do
                def cached_responses
                  upstream.cached_responses.default.search_by_relative_path(params[:search])
                end

                def cached_response
                  upstream.cached_responses.default.find_by_relative_path!(declared_params[:cached_response_id])
                end
              end

              desc 'List maven virtual registry upstream cached responses' do
                detail 'This feature was introduced in GitLab 17.4. \
                      This feature is currently in an experimental state. \
                      This feature is behind the `virtual_registry_maven` feature flag.'
                success Entities::VirtualRegistries::Packages::Maven::CachedResponse
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
                authorize! :read_virtual_registry, registry

                # TODO: refactor this when we support multiple upstreams.
                # https://gitlab.com/gitlab-org/gitlab/-/issues/480461
                not_found! if upstream&.id != params[:upstream_id]

                present paginate(cached_responses), with: Entities::VirtualRegistries::Packages::Maven::CachedResponse
              end

              desc 'Delete a maven virtual registry upstream cached response' do
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
                requires :cached_response_id, type: String, coerce_with: Base64.method(:urlsafe_decode64),
                  desc: 'The base64 encoded relative path of the cached response',
                  documentation: { example: 'Zm9vL2Jhci9teXBrZy5wb20=' }
              end

              delete '*cached_response_id' do
                authorize! :destroy_virtual_registry, registry

                # TODO: refactor this when we support multiple upstreams.
                # https://gitlab.com/gitlab-org/gitlab/-/issues/480461
                not_found! if upstream&.id != params[:upstream_id]

                destroy_conditionally!(cached_response) do |cached_response|
                  render_validation_error!(cached_response) unless cached_response.update(upstream: nil)
                end
              end
            end
          end
        end
      end
    end
  end
end
