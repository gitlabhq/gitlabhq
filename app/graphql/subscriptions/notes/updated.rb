# frozen_string_literal: true

module Subscriptions
  module Notes
    class Updated < Base
      payload_type Types::Notes::NoteType
    end
  end
end
