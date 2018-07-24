# frozen_string_literal: true

class BuildMetadataEntity < Grape::Entity
  expose :timeout_human_readable
  expose :timeout_source do |metadata|
    metadata.present.timeout_source
  end
end
