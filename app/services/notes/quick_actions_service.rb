# frozen_string_literal: true

# QuickActionsService class
#
# Executes quick actions commands extracted from note text
#
# Most commands returns parameters to be applied later
# using QuickActionService#apply_updates
#
module Notes
  class QuickActionsService < BaseService
    attr_reader :interpret_service

    delegate :commands_executed_count, to: :interpret_service, allow_nil: true

    UPDATE_SERVICES = {
      'Issue' => Issues::UpdateService,
      'MergeRequest' => MergeRequests::UpdateService,
      'Commit' => Commits::TagService
    }.freeze
    private_constant :UPDATE_SERVICES

    def self.update_services
      UPDATE_SERVICES
    end

    def self.noteable_update_service_class(note)
      update_services[note.noteable_type]
    end

    def self.supported?(note)
      !!noteable_update_service_class(note)
    end

    def supported?(note)
      self.class.supported?(note)
    end

    def execute(note, options = {})
      return [note.note, {}] unless supported?(note)

      @interpret_service = QuickActions::InterpretService.new(project, current_user, options)

      interpret_service.execute(note.note, note.noteable)
    end

    # Applies updates extracted to note#noteable
    # The update parameters are extracted on self#execute
    def apply_updates(update_params, note)
      return if update_params.empty?
      return unless supported?(note)

      # We need the `id` after the note is persisted
      if update_params[:spend_time]
        update_params[:spend_time][:note_id] = note.id
      end

      noteable_update_service_class = self.class.noteable_update_service_class(note)

      # TODO: This conditional is necessary because we have not fully converted all possible
      #   noteable_update_service_class classes to use named arguments. See more details
      #   on the partial conversion at https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59182
      #   Follow-on issue to address this is here:
      #   https://gitlab.com/gitlab-org/gitlab/-/issues/328734
      service =
        if noteable_update_service_class.respond_to?(:constructor_container_arg)
          noteable_update_service_class.new(**noteable_update_service_class.constructor_container_arg(note.resource_parent), current_user: current_user, params: update_params)
        else
          noteable_update_service_class.new(note.resource_parent, current_user, update_params)
        end

      service.execute(note.noteable)
    end
  end
end

Notes::QuickActionsService.prepend_mod_with('Notes::QuickActionsService')
