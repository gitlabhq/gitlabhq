# frozen_string_literal: true

module ContainerRegistry
  class ReferrerPolicy < BasePolicy
    delegate { @subject.tag }
  end
end
