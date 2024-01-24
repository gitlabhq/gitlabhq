# frozen_string_literal: true

module WorkItems
  module Callbacks
    class Notes < Base
      def before_update
        return unless params.present? && params.key?(:discussion_locked)
        return unless has_permission?(:set_work_item_metadata)

        work_item.discussion_locked = params[:discussion_locked]
      end
    end
  end
end
