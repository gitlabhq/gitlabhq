# frozen_string_literal: true

module DraftNotes
  class BaseService < ::BaseService
    attr_accessor :merge_request, :current_user, :params

    def initialize(merge_request, current_user, params = nil)
      @merge_request = merge_request
      @current_user = current_user
      @params = params.dup
    end

    def merge_request_activity_counter
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
    end

    private

    def draft_notes
      @draft_notes ||= merge_request.draft_notes.order_id_asc.authored_by(current_user)
    end

    def project
      merge_request.target_project
    end
  end
end
