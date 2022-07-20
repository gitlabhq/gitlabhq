# frozen_string_literal: true

module Projects
  module Harbor
    class ArtifactsController < ::Projects::Harbor::ApplicationController
      include ::Harbor::Artifact

      private

      def container
        @project
      end
    end
  end
end
