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

            scope.each do |model_instance|
              loader.call(model_instance.full_path.downcase, model_instance)
            end
          end
        end
      end
    end
  end
end
