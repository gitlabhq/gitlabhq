# frozen_string_literal: true

module API
  module Concerns
    module VirtualRegistries
      module Packages
        module Maven
          module RegistryEndpoints
            extend ActiveSupport::Concern

            included do
              desc 'Get the list of all maven virtual registries' do
                detail 'This feature was introduced in GitLab 17.4. \
                    This feature is currently in an experimental state. \
                    This feature is behind the `virtual_registry_maven` feature flag.'
                success ::API::Entities::VirtualRegistries::Packages::Maven::Registry
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
                requires :group_id, type: Integer, desc: 'The ID of the group', allow_blank: false
              end
              get do
                group = find_group!(declared_params[:group_id])
                authorize! :read_virtual_registry, ::VirtualRegistries::Packages::Policies::Group.new(group)

                registries = ::VirtualRegistries::Packages::Maven::Registry.for_group(group)

                present registries, with: ::API::Entities::VirtualRegistries::Packages::Maven::Registry
              end

              desc 'Create a new maven virtual registry' do
                detail 'This feature was introduced in GitLab 17.4. \
                    This feature is currently in an experimental state. \
                    This feature is behind the `virtual_registry_maven` feature flag.'
                success code: 201
                failure [
                  { code: 400, message: 'Bad request' },
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not found' }
                ]
                tags %w[maven_virtual_registries]
                hidden true
              end
              params do
                requires :group_id, type: Integer, desc: 'The ID of the group. Must be a top-level group',
                  allow_blank: false
                optional :cache_validity_hours, type: Integer, desc: 'The validity of the cache in hours. Defaults to 1'
              end
              post do
                group = find_group!(declared_params[:group_id])
                authorize! :create_virtual_registry, ::VirtualRegistries::Packages::Policies::Group.new(group)

                new_reg = ::VirtualRegistries::Packages::Maven::Registry.new(declared_params(include_missing: false))

                render_validation_error!(new_reg) unless new_reg.save

                created!
              end

              route_param :id, type: Integer, desc: 'The ID of the maven virtual registry' do
                desc 'Get a specific maven virtual registry' do
                  detail 'This feature was introduced in GitLab 17.4. \
                    This feature is currently in an experimental state. \
                    This feature is behind the `virtual_registry_maven` feature flag.'
                  success ::API::Entities::VirtualRegistries::Packages::Maven::Registry
                  failure [
                    { code: 400, message: 'Bad request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not found' }
                  ]
                  tags %w[maven_virtual_registries]
                  hidden true
                end
                get do
                  authorize! :read_virtual_registry, registry

                  present registry, with: ::API::Entities::VirtualRegistries::Packages::Maven::Registry
                end

                desc 'Update a specific maven virtual registry' do
                  detail 'This feature was introduced in GitLab 17.4. \
                    This feature is currently in an experimental state. \
                    This feature is behind the `virtual_registry_maven` feature flag.'
                  success ::API::Entities::VirtualRegistries::Packages::Maven::Registry
                  failure [
                    { code: 400, message: 'Bad request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not found' }
                  ]
                  tags %w[maven_virtual_registries]
                  hidden true
                end
                params do
                  requires :cache_validity_hours, type: Integer, desc: 'The validity of the cache in hours'
                end
                patch do
                  authorize! :update_virtual_registry, registry

                  render_validation_error!(registry) unless registry.update(declared_params)

                  present registry, with: ::API::Entities::VirtualRegistries::Packages::Maven::Registry
                end

                desc 'Delete a specific maven virtual registry' do
                  detail 'This feature was introduced in GitLab 17.4. \
                    This feature is currently in an experimental state. \
                    This feature is behind the `virtual_registry_maven` feature flag.'
                  success code: 204
                  failure [
                    { code: 400, message: 'Bad request' },
                    { code: 401, message: 'Unauthorized' },
                    { code: 403, message: 'Forbidden' },
                    { code: 404, message: 'Not found' },
                    { code: 412, message: 'Precondition Failed' }
                  ]
                  tags %w[maven_virtual_registries]
                  hidden true
                end
                delete do
                  authorize! :destroy_virtual_registry, registry

                  destroy_conditionally!(registry)
                end
              end
            end
          end
        end
      end
    end
  end
end
