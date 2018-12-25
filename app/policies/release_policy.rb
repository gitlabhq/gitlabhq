# frozen_string_literal: true

class ReleasePolicy < BasePolicy
  delegate { @subject.project }
end
