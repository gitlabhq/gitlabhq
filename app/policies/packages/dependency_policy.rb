# frozen_string_literal: true

module Packages
  class DependencyPolicy < BasePolicy
    delegate { @subject.project&.packages_policy_subject }
  end
end
