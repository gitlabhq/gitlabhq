# frozen_string_literal: true

module Terraform
  class StateVersionPolicy < BasePolicy
    alias_method :terraform_state_version, :subject

    delegate { terraform_state_version.terraform_state }
  end
end
