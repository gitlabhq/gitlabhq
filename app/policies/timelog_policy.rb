# frozen_string_literal: true

class TimelogPolicy < BasePolicy
  delegate { @subject.issuable }
end
