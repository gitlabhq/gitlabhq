# frozen_string_literal: true

module WorkItems
  class ReorderService
    include Gitlab::Utils::StrongMemoize

    def initialize(current_user:, params:)
      @current_user = current_user
      @params = params
    end

    def execute(work_item)
      return unauthorized_error(work_item) unless current_user.can?(:update_work_item, work_item)
      return missing_arguments_error(work_item) unless move_between_ids

      ::WorkItems::UpdateService.new(
        container: work_item.project,
        current_user: current_user,
        params: { move_between_ids: move_between_ids }
      ).execute(work_item)

      success(work_item)
    rescue ActiveRecord::RecordNotFound
      error(work_item, message: "Work item not found")
    end

    private

    attr_reader :current_user, :params

    def success(work_item)
      ServiceResponse.success(payload: {
        work_item: work_item,
        errors: []
      })
    end

    def unauthorized_error(work_item)
      error(
        work_item,
        message: "You don't have permissions to update this work item"
      )
    end

    def missing_arguments_error(work_item)
      error(work_item, message: 'At least one of move_before_id or move_after_id is required')
    end

    def error(work_item, message: nil)
      ServiceResponse.new(status: :error, payload: {
        work_item: work_item,
        errors: Array.wrap(message)
      })
    end

    def move_between_ids
      params
        .values_at(:move_before_id, :move_after_id)
        .map(&:to_i)
        .map { |id| id > 0 ? id : nil }
        .then { |ids| ids.any? ? ids : nil }
    end
    strong_memoize_attr :move_between_ids
  end
end
