# frozen_string_literal: true

class WorkItemPolicy < BasePolicy
  delegate { @subject.project }
end
