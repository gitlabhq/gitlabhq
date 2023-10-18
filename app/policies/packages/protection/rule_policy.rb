# frozen_string_literal: true

module Packages
  module Protection
    class RulePolicy < BasePolicy
      delegate { @subject.project }
    end
  end
end
