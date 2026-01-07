# frozen_string_literal: true

module Namespaces
  module Groups
    class UnarchiveService < ::Groups::BaseService
      include ::Namespaces::Groups::ArchiveEvents

      NotAuthorizedError = ServiceResponse.error(
        message: "You don't have permissions to unarchive this group!"
      )
      AlreadyUnarchivedError = ServiceResponse.error(
        message: 'Group is already unarchived!'
      )
      AncestorArchivedError = ServiceResponse.error(
        message: 'Cannot unarchive group since one of the ancestor groups is archived!'
      )

      Error = Class.new(StandardError)
      UpdateError = Class.new(Error)

      def execute
        return NotAuthorizedError unless can?(current_user, :archive_group, group)
        return AncestorArchivedError if group.ancestors_archived?
        return AlreadyUnarchivedError unless group.archived

        if unarchive_descendants?
          group.transaction do
            group.unarchive_descendants!
            group.unarchive_all_projects!
            unarchive_group
          end
        else
          unarchive_group
        end

        after_unarchive
        ServiceResponse.success
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, StateMachines::InvalidTransition
        ServiceResponse.error(message: "Failed to unarchive group! #{group.errors.full_messages.to_sentence}")
      end

      private

      def unarchive_group
        Namespace.transaction do
          group.unarchive!(transition_user: current_user)
          group.namespace_settings.update!(archived: false)
        end
      end

      def after_unarchive
        system_hook_service.execute_hooks_for(group, :update)
        publish_events
      end

      def error_response(message)
        ServiceResponse.error(message: message)
      end

      def unarchive_descendants?
        Feature.enabled?(:cascade_unarchive_group, group, type: :gitlab_com_derisk)
      end
    end
  end
end

Namespaces::Groups::UnarchiveService.prepend_mod
