# frozen_string_literal: true

module Ci
  module HasCompletionReason
    extend ActiveSupport::Concern

    class_methods do
      def rules_failure_message
        "the resulting pipeline would have been empty. Review the " \
          "[rules](#{Rails.application.routes.url_helpers.help_page_url('ci/yaml/index', anchor: 'rules')}) " \
          "configuration for the relevant jobs."
      end

      def workflow_rules_failure_message
        "the pipeline did not run. Review the " \
          "[workflow:rules](#{Rails.application.routes.url_helpers.help_page_url('ci/yaml/index',
            anchor: 'workflowrules')}) " \
        "configuration for the pipeline."
      end
    end
  end
end
