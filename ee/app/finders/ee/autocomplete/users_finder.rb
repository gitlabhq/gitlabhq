# frozen_string_literal: true

module EE
  module Autocomplete
    module UsersFinder
      extend ::Gitlab::Utils::Override

      attr_reader :skip_ldap, :push_code_to_protected_branches, :push_code

      override :initialize
      def initialize(params:, current_user:, project:, group:)
        super

        @skip_ldap = params[:skip_ldap]
        @push_code_to_protected_branches = params[:push_code_to_protected_branches]
        @push_code = params[:push_code]
      end

      override :find_users
      def find_users
        users = super

        skip_ldap == 'true' ? users.non_ldap : users
      end

      override :limited_users
      def limited_users
        load_users_by_push_ability(super)
      end

      def load_users_by_push_ability(items)
        return items unless project

        ability = push_ability
        return items if ability.blank?

        items.to_a
          .select { |user| user.can?(ability, project) }
      end

      def push_ability
        if push_code_to_protected_branches.present?
          :push_code_to_protected_branches
        elsif push_code.present?
          :push_code
        end
      end
    end
  end
end
