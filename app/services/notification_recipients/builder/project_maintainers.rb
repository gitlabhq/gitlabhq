# frozen_string_literal: true

module NotificationRecipients
  module Builder
    class ProjectMaintainers < Base
      attr_reader :target

      def initialize(target, action:)
        @target = target
        @action = action
      end

      def build!
        return [] unless project

        add_recipients(project.team.maintainers, :mention, nil)
        add_recipients(project.team.owners, :mention, nil)
      end

      def acting_user
        nil
      end
    end
  end
end
