# frozen_string_literal: true

module Gitlab
  module Auth
    class Result
      attr_reader :actor, :project, :type, :authentication_abilities

      def initialize(actor, project, type, authentication_abilities)
        @actor = actor
        @project = project
        @type = type
        @authentication_abilities = authentication_abilities
      end

      EMPTY = self.new(nil, nil, nil, nil).freeze

      def ci?(for_project)
        type == :ci &&
          project &&
          project == for_project
      end

      def lfs_deploy_token?(for_project)
        type == :lfs_deploy_token &&
          actor.try(:has_access_to?, for_project)
      end

      def success?
        actor.present? || type == :ci
      end

      def failed?
        !success?
      end

      def auth_user
        actor.is_a?(User) ? actor : nil
      end
      alias_method :user, :auth_user

      def deploy_token
        actor.is_a?(DeployToken) ? actor : nil
      end

      def can?(action)
        actor&.can?(action)
      end

      def can_perform_action_on_project?(action, given_project)
        Ability.allowed?(actor, action, given_project)
      end

      def authentication_abilities_include?(ability)
        return false if authentication_abilities.blank?

        authentication_abilities.include?(ability)
      end
    end
  end
end

Gitlab::Auth::Result.prepend_mod_with('Gitlab::Auth::Result')
