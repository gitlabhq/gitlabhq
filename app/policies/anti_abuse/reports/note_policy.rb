# frozen_string_literal: true

module AntiAbuse
  module Reports
    class NotePolicy < BasePolicy
      delegate { @subject.abuse_report }
    end
  end
end
