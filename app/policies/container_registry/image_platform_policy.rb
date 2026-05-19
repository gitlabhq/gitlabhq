# frozen_string_literal: true

module ContainerRegistry
  class ImagePlatformPolicy < BasePolicy
    delegate { @subject.parent }
  end
end
