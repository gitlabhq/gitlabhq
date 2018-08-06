# frozen_string_literal: true

class ExternalIssuePolicy < BasePolicy
  delegate { @subject.project }
end
