require 'uri'

if Gitlab.config.gitaly.enabled || Rails.env.test?
  Gitlab.config.repositories.storages.keys.each do |storage|
    # Force validation of each address
    Gitlab::GitalyClient.address(storage)
  end
end
