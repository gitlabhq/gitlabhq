# frozen_string_literal: true

module QA
  module Resource
    # Helper for approval configuration which exists on project and mr level
    module ApprovalConfiguration
      include ApiFabricator

      def api_approval_configuration_path
        "#{api_get_path}/approvals"
      end

      def api_approval_rules_path
        "#{api_get_path}/approval_rules"
      end

      # Approval configuration
      #
      # @return [Hash]
      def approval_configuration
        parse_body(api_get_from(api_approval_configuration_path))
      end

      # Update approvals configuration
      # MR: https://docs.gitlab.com/ee/api/merge_request_approvals.html#change-approval-configuration
      # Project: https://docs.gitlab.com/ee/api/merge_request_approvals.html#change-configuration
      #
      # @param [Hash] configuration
      # @return [Hash]
      def update_approval_configuration(configuration)
        api_post_to(api_approval_configuration_path, configuration)
      end

      # Approval rules
      #
      # @return [Array<Hash>]
      def fetch_approval_rules
        parse_body(api_get_from(api_approval_rules_path))
      end

      # Create approval rules
      #
      # @return [Hash]
      def create_approval_rules
        raise("Trying to create approval rules but no rules set!") unless approval_rules

        rule = { approvals_required: 1, name: "Approval rule for mr #{title}" }
        rule[:user_ids] = approval_rules[:users].map(&:id) if approval_rules[:users]
        rule[:group_ids] = approval_rules[:group].map(&:full_path) if approval_rules[:groups]

        api_post_to(api_approvals_path, rule)
      end
    end
  end
end
