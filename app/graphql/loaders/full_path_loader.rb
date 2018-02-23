module Loaders::FullPathLoader
  include Loaders::BaseLoader

  class << self
    def project(obj, args, ctx)
      project_by_full_path(args[:full_path])
    end

    def project_by_full_path(full_path)
      model_by_full_path(Project, full_path)
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
