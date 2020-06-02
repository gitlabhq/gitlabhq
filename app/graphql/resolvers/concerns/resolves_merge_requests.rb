# frozen_string_literal: true

# Mixin for resolving merge requests. All arguments must be in forms
# that `MergeRequestsFinder` can handle, so you may need to use aliasing.
module ResolvesMergeRequests
  extend ActiveSupport::Concern

  included do
    type Types::MergeRequestType, null: true
  end

  def resolve(**args)
    args[:iids] = Array.wrap(args[:iids]) if args[:iids]
    args.compact!

    if project && args.keys == [:iids]
      batch_load_merge_requests(args[:iids])
    else
      args[:project_id] ||= project

      MergeRequestsFinder.new(current_user, args).execute
    end.then(&(single? ? :first : :itself))
  end

  def ready?(**args)
    return early_return if no_results_possible?(args)

    super
  end

  def early_return
    [false, single? ? nil : MergeRequest.none]
  end

  private

  def batch_load_merge_requests(iids)
    iids.map { |iid| batch_load(iid) }.select(&:itself) # .compact doesn't work on BatchLoader
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def batch_load(iid)
    BatchLoader::GraphQL.for(iid.to_s).batch(key: project) do |iids, loader, args|
      args[:key].merge_requests.where(iid: iids).each do |mr|
        loader.call(mr.iid.to_s, mr)
      end
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
