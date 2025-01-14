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

    SUPPORTED_NOTEABLES = %w[WorkItem Issue MergeRequest Commit].freeze

    private_constant :SUPPORTED_NOTEABLES

    def self.supported_noteables
      SUPPORTED_NOTEABLES
    end

    def self.supported?(note)
      return true if note.for_work_item?

      supported_noteables.include? note.noteable_type
    end

    def supported?(note)
      self.class.supported?(note)
    end

    def execute(note, options = {})
      return [note.note, {}] unless supported?(note)

      @interpret_service = QuickActions::InterpretService.new(
        container: note.resource_parent,
        current_user: current_user,
        params: options.merge(discussion_id: note.discussion_id)
      )

      # NOTE: old_note would be nil if the note hasn't changed or it is a new record
      old_note, _ = note.note_change

      interpret_service.execute_with_original_text(note.note, note.noteable, original_text: old_note)
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

      execute_triggers(note, update_params)
      execute_update_service(note, update_params)
    end

    private

    def execute_triggers(note, params)
      # This is overridden in EE
    end

    def execute_update_service(note, params)
      service_response = noteable_update_service(note, params).execute(note.noteable)

      service_errors = if service_response.respond_to?(:errors)
                         service_response.errors.full_messages
                       elsif service_response.respond_to?(:[]) && service_response[:status] == :error
                         Array.wrap(service_response[:message])
                       end

      service_errors.blank? ? ServiceResponse.success : ServiceResponse.error(message: service_errors)
    end

    def noteable_update_service(note, update_params)
      if note.for_work_item?
        parsed_params = note.noteable.transform_quick_action_params(update_params)

        WorkItems::UpdateService.new(
          container: note.resource_parent,
          current_user: current_user,
          params: parsed_params[:common],
          widget_params: parsed_params[:widgets]
        )
      elsif note.for_issue?
        Issues::UpdateService.new(container: note.resource_parent, current_user: current_user, params: update_params)
      elsif note.for_merge_request?
        MergeRequests::UpdateService.new(
          project: note.resource_parent, current_user: current_user, params: update_params
        )
      elsif note.for_commit?
        Commits::TagService.new(note.resource_parent, current_user, update_params)
      end
    end
  end
end

Notes::QuickActionsService.prepend_mod
