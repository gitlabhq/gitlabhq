# frozen_string_literal: true

module Projects
  module Members
    class EffectiveAccessLevelPerUserFinder < EffectiveAccessLevelFinder
      def initialize(project, user)
        @project = project
        @user = user
      end

      private

      attr_reader :user

      def apply_scopes(members)
        super.where(user_id: user.id) # rubocop: disable CodeReuse/ActiveRecord
      end
    end
  end
end
