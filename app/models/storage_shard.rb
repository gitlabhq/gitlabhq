# This is an in-memory structure only. The repository storage configuration is
# in gitlab.yml and not in the database. This model makes it easier to work
# with the configuration.
class StorageShard
  include ActiveModel::Model

  attr_accessor :name, :path, :gitaly_address, :gitaly_token
  attr_accessor :failure_count_threshold, :failure_reset_time, :failure_wait_time
  attr_accessor :storage_timeout

  validates :name, presence: true
  validates :path, presence: true

  # Generates an array of StorageShard objects from the currrent storage
  # configuration using the gitlab.yml array of key/value pairs:
  #
  # {"default"=>{"path"=>"/home/git/repositories", ...}
  #
  # The key is the shard name, and the values are the parameters for that shard.
  def self.current_shards
    Settings.repositories.storages.map do |name, params|
      config = params.symbolize_keys.merge(name: name)
      StorageShard.new(config)
    end
  end
end
