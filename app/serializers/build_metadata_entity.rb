class BuildMetadataEntity < Grape::Entity
  expose :used_timeout_human_readable do |metadata|
    metadata.used_timeout_human_readable unless metadata.used_timeout.nil?
  end

  expose :timeout_source do |metadata|
    metadata.present.timeout_source
  end
end
