# frozen_string_literal: true

module MergeRequests
  class ResolveTodosService
    include BaseServiceUtility

    def initialize(merge_request, user)
      @merge_request = merge_request
      @user = user
    end

    def async_execute
      if Feature.enabled?(:resolve_merge_request_todos_async, merge_request.target_project, default_enabled: :yaml)
        MergeRequests::ResolveTodosWorker.perform_async(merge_request.id, user.id)
      else
        execute
      end
    end

    def execute
      todo_service.resolve_todos_for_target(merge_request, user)
    end

    private

    attr_reader :merge_request, :user
  end
end
