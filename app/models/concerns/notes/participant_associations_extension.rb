# frozen_string_literal: true

module Notes
  module ParticipantAssociationsExtension
    def authors_loaded?
      loaded? && to_a.all? { |note| note.association(:author).loaded? }
    end

    def award_emojis_loaded?
      loaded? && to_a.all? { |note| note.association(:award_emoji).loaded? }
    end
  end
end
