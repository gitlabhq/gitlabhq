# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      # Suitable for use to find resources that expose `where_full_path_in`,
      # such as Project, Group, Namespace
      # full path is always converted to lowercase for case-insensitive results
      class FullPathModelLoader
        attr_reader :model_class, :full_path

        def initialize(model_class, full_path)
          @model_class = model_class
          @full_path = full_path.downcase
        end

        def find
          BatchLoader::GraphQL.for(full_path).batch(key: model_class) do |full_paths, loader, args|
            scope = args[:key]
            scope = if scope == Namespace
                      scope.id_in(Route.by_paths(full_paths).select(:namespace_id)).with_route
                    else
                      scope.where_full_path_in(full_paths)
                    end

            requested = full_paths.to_set

            scope.each do |model_instance|
              computed_full_path = model_instance.full_path.downcase

              unless requested.include?(computed_full_path)
                log_unmatched_full_path(args[:key], model_instance, computed_full_path)
              end

              loader.call(computed_full_path, model_instance)
            end
          end
        end

        private

        def log_unmatched_full_path(model_class, model_instance, computed_full_path)
          Gitlab::AppLogger.error(
            message: 'FullPathModelLoader computed full_path did not match a requested key',
            class: self.class.name,
            model_class: model_class.name,
            model_id: model_instance.id,
            computed_full_path: computed_full_path
          )
        end
      end
    end
  end
end
