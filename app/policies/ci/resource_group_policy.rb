# frozen_string_literal: true

module Ci
  class ResourceGroupPolicy < BasePolicy
    delegate { @subject.project }
  end
end
