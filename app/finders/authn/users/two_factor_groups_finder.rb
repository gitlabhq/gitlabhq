# frozen_string_literal: true

module Authn
  module Users
    class TwoFactorGroupsFinder
      def initialize(user, source_only: false)
        @user = user
        @source_only = source_only
      end

      def execute
        return source_groups_of_requirement if source_only

        expanded_groups_requiring_two_factor_authentication
      end

      private

      attr_reader :user, :source_only

      def source_groups_of_requirement
        ::Gitlab::ObjectHierarchy
          .new(expanded_groups_requiring_two_factor_authentication)
          .all_objects
          .id_in(groups_with_at_least_minimal_access)
      end

      def expanded_groups_requiring_two_factor_authentication
        all_expanded_groups.requiring_two_factor_authentication(true)
      end

      def all_expanded_groups
        groups = groups_with_at_least_minimal_access
        return groups if groups.empty?

        ::Gitlab::ObjectHierarchy.new(groups).all_objects
      end

      def groups_with_at_least_minimal_access
        user.groups
      end
    end
  end
end

Authn::Users::TwoFactorGroupsFinder.prepend_mod
