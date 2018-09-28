# frozen_string_literal: true

module Resolvers
  module FullPathResolver
    extend ActiveSupport::Concern

    prepended do
      argument :full_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The full path of the project or namespace, e.g., "gitlab-org/gitlab-ce"'
    end

    def model_by_full_path(model, full_path)
      BatchLoader.for(full_path).batch(key: "#{model.model_name.param_key}:full_path") do |full_paths, loader|
        # `with_route` avoids an N+1 calculating full_path
        results = model.where_full_path_in(full_paths).with_route
        results.each { |project| loader.call(project.full_path, project) }
      end
    end
  end
end
