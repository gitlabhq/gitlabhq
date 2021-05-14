# frozen_string_literal: true

module MergeRequests
  class ResolveTodosService
    include BaseServiceUtility

    def initialize(merge_request, user)
      @merge_request = merge_request
      @user = user
    end

    def async_execute
      MergeRequests::ResolveTodosWorker.perform_async(merge_request.id, user.id)
    end

    def execute
      todo_service.resolve_todos_for_target(merge_request, user)
    end

    private

    attr_reader :merge_request, :user
  end
end
