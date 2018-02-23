class Loaders::IidLoader
  include Loaders::BaseLoader

  class << self
    def merge_request(obj, args, ctx)
      iid = args[:iid]
      project = Loaders::FullPathLoader.project_by_full_path(args[:project])
      merge_request_by_project_and_iid(project, iid)
    end

    def merge_request_by_project_and_iid(project_loader, iid)
      project_id = project_loader.__sync&.id

      # IIDs are represented as the GraphQL `id` type, which is a string
      BatchLoader.for(iid.to_s).batch(key: "merge_request:target_project:#{project_id}:iid") do |iids, loader|
        if project_id
          results = MergeRequest.where(target_project_id: project_id, iid: iids)
          results.each { |mr| loader.call(mr.iid.to_s, mr) }
        end
      end
    end
  end
end
