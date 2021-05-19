# frozen_string_literal: true

module Boards
  module Lists
    # This class is used by issue and epic board lists
    # for destroying a single list
    class BaseDestroyService < Boards::BaseService
      def execute(list)
        unless list.destroyable?
          return ServiceResponse.error(message: "Open and closed lists on a board cannot be destroyed.")
        end

        list.with_lock do
          decrement_higher_lists(list)
          list.destroy!
        end

        ServiceResponse.success
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        ServiceResponse.error(message: "List destroy failed.")
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def decrement_higher_lists(list)
        list.board.lists.movable.where('position > ?', list.position)
            .update_all('position = position - 1')
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
