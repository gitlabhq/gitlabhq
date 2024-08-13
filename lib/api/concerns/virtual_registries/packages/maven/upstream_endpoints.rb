# frozen_string_literal: true

module API
  module Concerns
    module VirtualRegistries
      module Packages
        module Maven
          module UpstreamEndpoints
            extend ActiveSupport::Concern

            included do
              desc 'List all maven virtual registry upstreams' do
                detail 'This feature was introduced in GitLab 17.3. \
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

                present [upstream].compact, with: Entities::VirtualRegistries::Packages::Maven::Upstream
              end

              desc 'Add a maven virtual registry upstream' do
                detail 'This feature was introduced in GitLab 17.3. \
                      This feature is currently in experiment state. \
                      This feature behind the `virtual_registry_maven` feature flag.'
                success code: 201
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
                requires :url, type: String, desc: 'The URL of the maven virtual registry upstream', allow_blank: false
                optional :username, type: String, desc: 'The username of the maven virtual registry upstream'
                optional :password, type: String, desc: 'The password of the maven virtual registry upstream'
                all_or_none_of :username, :password
              end
              post do
                authorize! :create_virtual_registry, registry

                conflict!(_('Upstream already exists')) if upstream

                registry.build_upstream(declared_params.merge(group: group))
                registry_upstream.group = group

                ApplicationRecord.transaction do
                  render_validation_error!(upstream) unless upstream.save
                  render_validation_error!(registry_upstream) unless registry_upstream.save
                end

                created!
              end

              route_param :upstream_id, type: Integer, desc: 'The ID of the maven virtual registry upstream' do
                desc 'Get a specific maven virtual registry upstream' do
                  detail 'This feature was introduced in GitLab 17.3. \
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

                  not_found! if upstream&.id != params[:upstream_id]

                  present upstream, with: Entities::VirtualRegistries::Packages::Maven::Upstream
                end

                desc 'Update a maven virtual registry upstream' do
                  detail 'This feature was introduced in GitLab 17.3. \
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
                  optional :url, type: String, desc: 'The URL of the maven virtual registry upstream',
                    allow_blank: false
                  optional :username, type: String, desc: 'The username of the maven virtual registry upstream',
                    allow_blank: false
                  optional :password, type: String, desc: 'The password of the maven virtual registry upstream',
                    allow_blank: false
                  at_least_one_of :url, :username, :password
                end
                patch do
                  authorize! :update_virtual_registry, registry

                  render_validation_error!(upstream) unless upstream.update(declared_params(include_missing: false))

                  status :ok
                end

                desc 'Delete a maven virtual registry upstream' do
                  detail 'This feature was introduced in GitLab 17.3. \
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
                  authorize! :destroy_virtual_registry, registry

                  not_found! if upstream&.id != params[:upstream_id]

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
