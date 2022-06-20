# frozen_string_literal: true

module Packages
  module Cleanup
    class PolicyPolicy < BasePolicy
      delegate { @subject.project }
    end
  end
end
