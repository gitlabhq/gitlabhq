# frozen_string_literal: true

module Groups
  module Harbor
    class ArtifactsController < ::Groups::Harbor::ApplicationController
      include ::Harbor::Artifact

      private

      def container
        @group
      end
    end
  end
end
