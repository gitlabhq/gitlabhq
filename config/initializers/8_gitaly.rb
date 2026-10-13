# frozen_string_literal: true

require 'uri'

Gitlab.config.repositories.storages.keys.each do |storage|
  # Force validation of each address, including a gitway_address the route_gitaly_through_gitway flag does not
  # currently select. This deliberately does not evaluate the flag: the database may not exist yet.
  Gitlab::GitalyClient.validate_storage_addresses!(storage)
end
