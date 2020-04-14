# frozen_string_literal: true

module Resolvers
  class MergeRequestsResolver < BaseResolver
    argument :iid, GraphQL::STRING_TYPE,
              required: false,
              description: 'IID of the merge request, for example `1`'

    argument :iids, [GraphQL::STRING_TYPE],
              required: false,
              description: 'Array of IIDs of merge requests, for example `[1, 2]`'

    type Types::MergeRequestType, null: true

    alias_method :project, :object

    def resolve(**args)
      project = object.respond_to?(:sync) ? object.sync : object
      return MergeRequest.none if project.nil?

      args[:iids] ||= [args[:iid]].compact

      if args[:iids].any?
        batch_load_merge_requests(args[:iids])
      else
        args[:project_id] = project.id

        MergeRequestsFinder.new(context[:current_user], args).execute
      end
    end

    def batch_load_merge_requests(iids)
      iids.map { |iid| batch_load(iid) }.select(&:itself) # .compact doesn't work on BatchLoader
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def batch_load(iid)
      BatchLoader::GraphQL.for(iid.to_s).batch(key: project) do |iids, loader, args|
        arg_key = args[:key].respond_to?(:sync) ? args[:key].sync : args[:key]

        arg_key.merge_requests.where(iid: iids).each do |mr|
          loader.call(mr.iid.to_s, mr)
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
