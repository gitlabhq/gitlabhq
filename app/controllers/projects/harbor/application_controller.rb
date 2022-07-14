# frozen_string_literal: true

module Projects
  module Harbor
    class ApplicationController < Projects::ApplicationController
      layout 'project'
      include ::Harbor::Access

      private

      def authorize_read_harbor_registry!
        render_404 unless can?(current_user, :read_harbor_registry, @project)
      end
    end
  end
end
