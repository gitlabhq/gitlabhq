# frozen_string_literal: true

module AntiAbuse
  module Reports
    class IndividualNoteDiscussion < Discussion
      def individual_note?
        true
      end

      def can_convert_to_discussion?
        true
      end

      def convert_to_discussion!
        first_note.becomes!(Discussion.note_class).to_discussion
      end
    end
  end
end
