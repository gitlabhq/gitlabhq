module Resolvers
  class MergeRequestResolver < BaseResolver
    argument :iid, GraphQL::ID_TYPE,
             required: true,
             description: 'The IID of the merge request, e.g., "1"'

    type Types::MergeRequestType, null: true

    alias_method :project, :object

    def resolve(iid:)
      return unless project.present?

      BatchLoader.for(iid.to_s).batch(key: project.id) do |iids, loader|
        results = project.merge_requests.where(iid: iids)
        results.each { |mr| loader.call(mr.iid.to_s, mr) }
      end
    end
  end
end
