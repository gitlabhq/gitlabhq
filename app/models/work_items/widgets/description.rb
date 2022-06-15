# frozen_string_literal: true

module WorkItems
  module Widgets
    class Description < Base
      delegate :description, to: :work_item

      def update(params:)
        work_item.description = params[:description] if params&.key?(:description)
      end
    end
  end
end
