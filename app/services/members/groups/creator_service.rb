# frozen_string_literal: true

module Members
  module Groups
    class CreatorService < Members::CreatorService
      def self.access_levels
        Gitlab::Access.sym_options_with_owner
      end

      private

      def can_update_member?
        super || current_user.can?(:update_group_member, member)
      end
    end
  end
end
