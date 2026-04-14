# frozen_string_literal: true

module Terraform
  class StateProtectionRulePolicy < BasePolicy
    delegate { @subject.project }
  end
end
