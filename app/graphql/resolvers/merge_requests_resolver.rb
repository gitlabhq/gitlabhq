# frozen_string_literal: true

module Resolvers
  class MergeRequestsResolver < BaseResolver
    argument :iid, GraphQL::STRING_TYPE,
              required: false,
              description: 'The IID of the merge request, e.g., "1"'

    argument :iids, [GraphQL::STRING_TYPE],
              required: false,
              description: 'The list of IIDs of issues, e.g., [1, 2]'

    type Types::MergeRequestType, null: true

    alias_method :project, :object

    def resolve(**args)
      return unless project.present?

      args[:iids] ||= [args[:iid]].compact

      args[:iids].map { |iid| batch_load(iid) }
        .select(&:itself) # .compact doesn't work on BatchLoader
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def batch_load(iid)
      BatchLoader.for(iid.to_s).batch(key: project) do |iids, loader, args|
        args[:key].merge_requests.where(iid: iids).each do |mr|
          loader.call(mr.iid.to_s, mr)
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
