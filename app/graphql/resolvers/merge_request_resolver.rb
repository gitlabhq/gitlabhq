module Resolvers
  class MergeRequestResolver < BaseResolver
    prepend FullPathResolver

    type Types::ProjectType, null: true

    argument :iid, GraphQL::ID_TYPE,
             required: true,
             description: 'The IID of the merge request, e.g., "1"'

    def resolve(full_path:, iid:)
      project = model_by_full_path(Project, full_path)
      return unless project.present?

      BatchLoader.for(iid.to_s).batch(key: project.id) do |iids, loader|
        results = project.merge_requests.where(iid: iids)
        results.each { |mr| loader.call(mr.iid.to_s, mr) }
      end
    end
  end
end
