# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckMergeRequestTitleRegexService < CheckBaseService
      identifier :title_regex
      description 'Checks whether the title matches the expected regex'

      def execute
        return inactive unless validate_title_regex?

        if valid_project_regex
          success
        else
          failure
        end
      end

      def skip?
        params[:skip_merge_request_title_check].present?
      end

      def cacheable?
        false
      end

      private

      def valid_project_regex
        project_regex = project.merge_request_title_regex

        return unless project_regex.present?

        regexp = Gitlab::UntrustedRegexp.with_fallback(project_regex)

        regexp === merge_request.title
      end

      def validate_title_regex?
        Feature.enabled?(:merge_request_title_regex, project) && project.merge_request_title_regex.present?
      end

      def project
        merge_request.project
      end
    end
  end
end
