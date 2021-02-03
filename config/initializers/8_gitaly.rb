# frozen_string_literal: true

require 'uri'

Gitlab.config.repositories.storages.keys.each do |storage|
  # Force validation of each address
  Gitlab::GitalyClient.address(storage)
end
