# frozen_string_literal: true

class DescriptionVersionPolicy < BasePolicy
  delegate { @subject.issuable }
end
