# frozen_string_literal: true

module Terraform
  class StatePolicy < BasePolicy
    alias_method :terraform_state, :subject

    delegate { terraform_state.project }
  end
end
