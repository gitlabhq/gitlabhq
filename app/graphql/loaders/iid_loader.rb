class Loaders::IidLoader < Loaders::BaseLoader
  class << self
    def merge_request(obj, args, ctx)
      iid = args[:iid]
      promise = Loaders::FullPathLoader.project_by_full_path(args[:project])

      promise.then do |project|
        if project
          merge_request_by_project_and_iid(project.id, iid)
        else
          nil
        end
      end
    end

    def merge_request_by_project_and_iid(project_id, iid)
      self.for(MergeRequest, target_project_id: project_id.to_s).load(iid.to_s)
    end
  end

  attr_reader :model, :restrictions

  def initialize(model, restrictions = {})
    @model = model
    @restrictions = restrictions
  end

  def perform(keys)
    relation = model.where(iid: keys)
    relation = relation.where(restrictions) if restrictions.present?

    # IIDs are represented as the GraphQL `id` type, which is a string
    fulfill_all(relation, keys) { |instance| instance.iid.to_s }
  end
end
