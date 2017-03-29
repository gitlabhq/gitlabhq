require 'uri'

# Make sure we initialize our Gitaly channels before Sidekiq starts multi-threaded execution.
if Gitlab.config.gitaly.enabled || Rails.env.test?
  Gitlab.config.repositories.storages.each do |name, params|
    address = params['gitaly_address']

    unless address.present?
      raise "storage #{name.inspect} is missing a gitaly_address"
    end

    unless URI(address).scheme == 'unix'
      raise "Unsupported Gitaly address: #{address.inspect}"
    end

    Gitlab::GitalyClient.configure_channel(name, address)
  end
end
