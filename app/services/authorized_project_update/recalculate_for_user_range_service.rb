# frozen_string_literal: true

module AuthorizedProjectUpdate
  class RecalculateForUserRangeService
    def initialize(start_user_id, end_user_id)
      @start_user_id = start_user_id
      @end_user_id = end_user_id
    end

    def execute
      User.where(id: start_user_id..end_user_id).select(:id).find_each do |user| # rubocop: disable CodeReuse/ActiveRecord
        Users::RefreshAuthorizedProjectsService.new(user, source: self.class.name).execute
      end
    end

    private

    attr_reader :start_user_id, :end_user_id
  end
end
