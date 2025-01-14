# frozen_string_literal: true

module Projects
  module MergeRequests
    class CreationsDiffsStreamController < Projects::MergeRequests::ApplicationController
      include StreamDiffs

      skip_before_action :merge_request
      before_action :authorize_create_merge_request_from!
      before_action :build_merge_request

      private

      def resource
        @merge_request.compare if @merge_request.can_be_created
      end
    end
  end
end
