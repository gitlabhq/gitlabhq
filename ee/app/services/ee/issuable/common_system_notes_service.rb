module EE
  module Issuable
    module CommonSystemNotesService
      extend ::Gitlab::Utils::Override
      attr_reader :issuable

      override :execute
      def execute(_issuable, _old_labels)
        super
        handle_weight_change_note
      end

      private

      def handle_weight_change_note
        if issuable.previous_changes.include?('weight')
          create_weight_change_note
        end
      end

      def create_weight_change_note
        ::SystemNoteService.change_weight_note(issuable, issuable.project, current_user)
      end
    end
  end
end
