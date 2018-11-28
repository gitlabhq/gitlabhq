# frozen_string_literal: true

module Resolvers
  class MergeRequestResolver < BaseResolver
    argument :iid, GraphQL::ID_TYPE,
             required: true,
             description: 'The IID of the merge request, e.g., "1"'

    type Types::MergeRequestType, null: true

    alias_method :project, :object

    # rubocop: disable CodeReuse/ActiveRecord
    def resolve(iid:)
      return unless project.present?

      BatchLoader.for(iid.to_s).batch(key: project) do |iids, loader, args|
        args[:key].merge_requests.where(iid: iids).each do |mr|
          loader.call(mr.iid.to_s, mr)
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
