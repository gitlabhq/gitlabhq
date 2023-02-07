# frozen_string_literal: true

module Subscriptions
  module Notes
    class Created < Base
      payload_type ::Types::Notes::NoteType
    end
  end
end
