# frozen_string_literal: true

module Ci
  module HasCompletionReason
    extend ActiveSupport::Concern

    class_methods do
      def rules_failure_message
        "The resulting pipeline would have been empty. Review the #{ci_docs_link('rules', 'rules')} " \
          "configuration for the relevant jobs."
      end

      def workflow_rules_failure_message
        "The pipeline did not run. Review the #{ci_docs_link('workflow:rules', 'workflowrules')} " \
          "configuration for the pipeline."
      end

      private

      def ci_docs_link(name, anchor)
        ApplicationController.helpers.link_to(
          name, Rails.application.routes.url_helpers.help_page_url('ci/yaml/_index.md', anchor: anchor)
        )
      end
    end
  end
end
