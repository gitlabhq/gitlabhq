# frozen_string_literal: true

module Ci
  class FreezePeriodPolicy < BasePolicy
    delegate { @subject.project }
  end
end
