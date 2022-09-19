# frozen_string_literal: true
module Packages
  class PackagePolicy < BasePolicy
    delegate { @subject.project&.packages_policy_subject }
  end
end
