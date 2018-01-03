module MergeRequests
  module Conflicts
    class ResolveService < MergeRequests::Conflicts::BaseService
      def execute(current_user, params)
        conflicts = Gitlab::Conflict::FileCollection.new(merge_request)

        conflicts.resolve(current_user, params[:commit_message], params[:files])
      end
    end
  end
end
