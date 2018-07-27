# frozen_string_literal: true

class DeploymentPolicy < BasePolicy
  delegate { @subject.project }
end
