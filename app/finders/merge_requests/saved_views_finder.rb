# frozen_string_literal: true

module MergeRequests
  class SavedViewsFinder
    def initialize(current_user)
      @current_user = current_user
    end

    def execute
      return ::MergeRequests::SavedView.none unless current_user

      ::MergeRequests::SavedView.for_user(current_user).order_id_asc
    end

    private

    attr_reader :current_user
  end
end
