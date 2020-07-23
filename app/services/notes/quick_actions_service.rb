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

    def self.noteable_update_service(note)
      update_services[note.noteable_type]
    end

    def self.supported?(note)
      !!noteable_update_service(note)
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

      self.class.noteable_update_service(note).new(note.resource_parent, current_user, update_params).execute(note.noteable)
    end
  end
end

Notes::QuickActionsService.prepend_if_ee('EE::Notes::QuickActionsService')
