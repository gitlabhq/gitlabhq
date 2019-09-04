# frozen_string_literal: true

module Resolvers
  module FullPathResolver
    extend ActiveSupport::Concern

    prepended do
      argument :full_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The full path of the project, group or namespace, e.g., "gitlab-org/gitlab-ce"'
    end

    def model_by_full_path(model, full_path)
      BatchLoader::GraphQL.for(full_path).batch(key: model) do |full_paths, loader, args|
        # `with_route` avoids an N+1 calculating full_path
        args[:key].where_full_path_in(full_paths).with_route.each do |model_instance|
          loader.call(model_instance.full_path, model_instance)
        end
      end
    end
  end
end
