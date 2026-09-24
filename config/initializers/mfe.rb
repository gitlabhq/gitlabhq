# frozen_string_literal: true

require 'gitlab/mfe'

# Wires the runtime hooks the gitlab-mfe gem needs but cannot reach on its own:
# whether delivery is enabled, the registry URL, and the path to the committed
# pin file. See gems/gitlab-mfe and ADR-004.
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
