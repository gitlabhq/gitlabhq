# frozen_string_literal: true

module DraftNotes
  class BaseService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    attr_accessor :merge_request, :current_user, :params

    def initialize(merge_request, current_user, params = {})
      @merge_request = merge_request
      @current_user = current_user
      @params = params.dup
    end

    def merge_request_activity_counter
      Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter
    end

    private

    def draft_notes
      drafts = merge_request.draft_notes.order_id_asc.authored_by(current_user)
      drafts = drafts.id_in(params[:ids]) if params[:ids].present?

      drafts
    end
    strong_memoize_attr :draft_notes

    def project
      merge_request.target_project
    end
  end
end
