class BuildMetadataEntity < Grape::Entity
  expose :timeout_human_readable do |metadata|
    metadata.timeout_human_readable unless metadata.timeout.nil?
  end

  expose :timeout_source do |metadata|
    metadata.present.timeout_source
  end
end
