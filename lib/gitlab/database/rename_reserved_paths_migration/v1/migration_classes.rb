module Gitlab
  module Database
    module RenameReservedPathsMigration
      module V1
        module MigrationClasses
          module Routable
            def full_path
              if route && route.path.present?
                @full_path ||= route.path # rubocop:disable Gitlab/ModuleWithInstanceVariables
              else
                update_route if persisted?

                build_full_path
              end
            end

            def build_full_path
              if parent && path
                parent.full_path + '/' + path
              else
                path
              end
            end

            def update_route
              prepare_route
              route.save
            end

            def prepare_route
              route || build_route(source: self)
              route.path = build_full_path
              @full_path = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables
            end
          end

          class Namespace < ActiveRecord::Base
            include MigrationClasses::Routable
            self.table_name = 'namespaces'
            belongs_to :parent,
                       class_name: "#{MigrationClasses.name}::Namespace"
            has_one :route, as: :source
            has_many :children,
                     class_name: "#{MigrationClasses.name}::Namespace",
                     foreign_key: :parent_id

            # Overridden to have the correct `source_type` for the `route` relation
            def self.name
              'Namespace'
            end

            def kind
              type == 'Group' ? 'group' : 'user'
            end
          end

          class User < ActiveRecord::Base
            self.table_name = 'users'
          end

          class Route < ActiveRecord::Base
            self.table_name = 'routes'
            belongs_to :source, polymorphic: true
          end

          class Project < ActiveRecord::Base
            include MigrationClasses::Routable
            has_one :route, as: :source
            self.table_name = 'projects'

            HASHED_STORAGE_FEATURES = {
              repository: 1,
              attachments: 2
            }.freeze

            def repository_storage_path
              Gitlab.config.repositories.storages[repository_storage].legacy_disk_path
            end

            # Overridden to have the correct `source_type` for the `route` relation
            def self.name
              'Project'
            end

            def hashed_storage?(feature)
              raise ArgumentError, "Invalid feature" unless HASHED_STORAGE_FEATURES.include?(feature)
              return false unless respond_to?(:storage_version)

              self.storage_version && self.storage_version >= HASHED_STORAGE_FEATURES[feature]
            end
          end
        end
      end
    end
  end
end
