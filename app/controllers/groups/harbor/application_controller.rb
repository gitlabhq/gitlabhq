# frozen_string_literal: true

module Groups
  module Harbor
    class ApplicationController < Groups::ApplicationController
      layout 'group'
      include ::Harbor::Access

      private

      def authorize_read_harbor_registry!
        render_404 unless can?(current_user, :read_harbor_registry, @group)
      end
    end
  end
end
