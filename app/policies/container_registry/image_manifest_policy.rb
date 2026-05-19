# frozen_string_literal: true

module ContainerRegistry
  class ImageManifestPolicy < BasePolicy
    delegate { @subject.tag }
  end
end
