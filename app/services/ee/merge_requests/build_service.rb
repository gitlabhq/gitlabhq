module EE
  module MergeRequests
    module BuildService
      def assign_title_and_description
        super

        assign_description_from_template
      end

      # Set MR description based on project template
      def assign_description_from_template
        return unless target_project.feature_available?(:issuable_default_templates) &&
            target_project.merge_requests_template.present?

        merge_request.description = target_project.merge_requests_template

        append_closes_description
      end
    end
  end
end
