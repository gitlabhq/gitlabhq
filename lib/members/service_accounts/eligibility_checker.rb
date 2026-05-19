# frozen_string_literal: true

module Members
  module ServiceAccounts
    class EligibilityChecker
      def initialize(target_group: nil, target_project: nil)
        raise ArgumentError, 'Cannot provide both target_group and target_project' if target_group && target_project

        if target_group && !target_group.is_a?(Group)
          raise ArgumentError, "target_group must be a Group, got #{target_group.class}"
        end

        if target_project && !target_project.is_a?(Project)
          raise ArgumentError, "target_project must be a Project, got #{target_project.class}"
        end

        @target_project = target_project
        @target_namespace = target_group || target_project&.namespace # populate for FF check and hierarchy logic
      end

      # rubocop:disable CodeReuse/ActiveRecord -- required for implementation of the service in multiple spots
      # Filters a User relation to only include users eligible for membership within target_namespace.
      def filter_users(users_relation)
        return users_relation if target_namespace.nil? && target_project.nil? # no-op as a safe default

        users_relation
          .left_joins(:user_detail)
          .joins(
            "LEFT JOIN namespaces AS provision_groups ON user_details.provisioned_by_group_id = provision_groups.id"
          )
          .where(*build_eligibility_conditions)
      end

      def eligible?(user)
        return true if target_namespace.nil? && target_project.nil? # no-op as a safe default
        return true unless user&.service_account?

        !restricted?(user)
      end

      private

      attr_reader :target_namespace, :target_project

      def restricted?(user)
        return false unless target_namespace
        return false unless user&.service_account?

        restricted_by_composite_identity?(user) ||
          restricted_by_subgroup_hierarchy?(user) ||
          restricted_by_project_provisioning?(user)
      end

      def build_eligibility_conditions
        conditions = []

        conditions << composite_identity_condition if composite_identity_restrictions_enabled?
        conditions << subgroup_hierarchy_condition
        conditions << project_provisioning_condition

        full_condition = "users.user_type != :sa_type OR (#{conditions.join(' AND ')})"

        [full_condition, query_params]
      end

      def composite_identity_condition
        <<~SQL.squish
          (
            users.composite_identity_enforced = FALSE
            OR user_details.provisioned_by_group_id IS NULL
            OR user_details.provisioned_by_group_id IN (:allowed_group_ids)
          )
        SQL
      end

      def subgroup_hierarchy_condition
        <<~SQL.squish
          (
            user_details.provisioned_by_group_id IS NULL
            OR user_details.provisioned_by_group_id IN (:allowed_group_ids)
            OR provision_groups.parent_id IS NULL
          )
        SQL
      end

      def project_provisioning_condition
        <<~SQL.squish
          (
            user_details.provisioned_by_project_id IS NULL
            OR (
              :target_is_project = TRUE
              AND user_details.provisioned_by_project_id = :target_project_id
            )
          )
        SQL
      end

      def query_params
        {
          sa_type: ::User.user_types[:service_account],
          allowed_group_ids: target_namespace.self_and_ancestor_ids,
          target_is_project: target_project.present?,
          target_project_id: target_project&.id
        }
      end

      # Composite identity restrictions are .com-only.
      # Overridden in EE via Gitlab::Saas.feature_available?(:service_accounts_invite_restrictions).
      def composite_identity_restrictions_enabled?
        false
      end

      def restricted_by_composite_identity?(user)
        return false unless composite_identity_restrictions_enabled?
        return false unless user.composite_identity_enforced?
        return false if user.provisioned_by_group_id.nil?

        !in_allowed_hierarchy?(user)
      end

      def restricted_by_subgroup_hierarchy?(user)
        provisioned_group = user.provisioned_by_group
        return false unless provisioned_group&.has_parent?

        !in_allowed_hierarchy?(user)
      end

      def in_allowed_hierarchy?(user)
        target_namespace.self_and_ancestor_ids.include?(user.provisioned_by_group_id)
      end

      def restricted_by_project_provisioning?(user)
        return false if user.provisioned_by_project_id.nil?

        # Project-provisioned SAs can only be invited to their origin project
        if target_project.present?
          user.provisioned_by_project_id != target_project.id
        else
          # Project-provisioned SAs cannot be invited to groups
          true
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end

Members::ServiceAccounts::EligibilityChecker.prepend_mod
