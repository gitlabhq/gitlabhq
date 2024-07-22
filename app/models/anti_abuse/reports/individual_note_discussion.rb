# frozen_string_literal: true

module AntiAbuse
  module Reports
    class IndividualNoteDiscussion < Discussion
      def individual_note?
        true
      end
    end
  end
end
