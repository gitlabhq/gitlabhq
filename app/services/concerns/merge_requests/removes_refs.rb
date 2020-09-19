# frozen_string_literal: true

module MergeRequests
  module RemovesRefs
    def cleanup_refs(merge_request)
      CleanupRefsService.schedule(merge_request)
    end
  end
end
