# frozen_string_literal: true
module Packages
  class PackagePolicy < BasePolicy
    delegate { @subject.project }
  end
end
