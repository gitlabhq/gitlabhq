# frozen_string_literal: true
module Packages
  class TagPolicy < BasePolicy
    delegate { @subject.package }
  end
end
