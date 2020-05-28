# frozen_string_literal: true

class ContainerExpirationPolicyPolicy < BasePolicy
  delegate { @subject.project }
end
