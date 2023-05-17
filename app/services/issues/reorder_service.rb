# frozen_string_literal: true

module Issues
  class ReorderService < Issues::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(issue)
      return false unless can?(current_user, :update_issue, issue)
      return false unless move_between_ids

      update(issue, { move_between_ids: move_between_ids })
    end

    private

    def update(issue, attrs)
      ::Issues::UpdateService.new(container: project, current_user: current_user, params: attrs).execute(issue)
    rescue ActiveRecord::RecordNotFound
      false
    end

    def move_between_ids
      strong_memoize(:move_between_ids) do
        ids = [params[:move_before_id], params[:move_after_id]]
                .map(&:to_i)
                .map { |m| m > 0 ? m : nil }

        ids.any? ? ids : nil
      end
    end
  end
end
