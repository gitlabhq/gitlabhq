# frozen_string_literal: true
module ContainerRegistry
  class TagPolicy < BasePolicy
    delegate { @subject.repository }
  end
end
