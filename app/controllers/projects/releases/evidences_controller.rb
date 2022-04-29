# frozen_string_literal: true

module Projects
  module Releases
    class EvidencesController < Projects::ApplicationController
      before_action :require_non_empty_project
      before_action :release
      before_action :authorize_read_release_evidence!

      feature_category :release_evidence
      urgency :low

      def show
        respond_to do |format|
          format.json do
            render json: evidence.summary
          end
        end
      end

      private

      def authorize_read_release_evidence!
        access_denied! unless can?(current_user, :read_release_evidence, evidence)
      end

      def release
        @release ||= project.releases.find_by_tag!(sanitized_tag_name)
      end

      def evidence
        release.evidences.find(params[:id])
      end

      def sanitized_tag_name
        CGI.unescape(params[:tag])
      end
    end
  end
end
