class Loaders::FullPathLoader < Loaders::BaseLoader
  class << self
    def project(obj, args, ctx)
      project_by_full_path(args[:full_path])
    end

    def project_by_full_path(full_path)
      self.for(Project).load(full_path)
    end
  end

  attr_reader :model

  def initialize(model)
    @model = model
  end

  def perform(keys)
    # `with_route` prevents relation.all.map(&:full_path)` from being N+1
    relation = model.where_full_path_in(keys).with_route
    fulfill_all(relation, keys, &:full_path)
  end
end
