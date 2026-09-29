# frozen_string_literal: true

require 'gitlab/mfe'

Gitlab::Mfe.configure do |config|
  config.enabled = -> do
    !!Gitlab.config.mfe.enabled && Feature.enabled?(:mfe_enabled, :instance)
  rescue ::Gitlab::Configs::MissingConfig
    # The `mfe` section is optional; a missing section means delivery is off.
    false
  end

  config.registry_url = -> do
    Gitlab.config.mfe.registry_url
  rescue ::Gitlab::Configs::MissingConfig
    # The `mfe` section is optional; fall back to the default registry.
    nil
  end

  config.vendor_file_path = -> { Rails.root.join('vendor/mfe.yml') }
end
