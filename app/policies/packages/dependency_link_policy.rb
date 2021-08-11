# frozen_string_literal: true
module Packages
  class DependencyLinkPolicy < BasePolicy
    delegate { @subject.package }
  end
end
