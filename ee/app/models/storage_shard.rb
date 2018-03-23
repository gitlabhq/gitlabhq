# This is an in-memory structure only. The repository storage configuration is
# in gitlab.yml and not in the database. This model makes it easier to work
# with the configuration.
class StorageShard
  include ActiveModel::Model

  attr_accessor :name, :path

  validates :name, presence: true
  validates :path, presence: true

  # Generates an array of StorageShard objects from the currrent storage
  # configuration using the gitlab.yml array of key/value pairs:
  #
  # {"default"=>{"path"=>"/home/git/repositories", ...}
  #
  # The key is the shard name, and the values are the parameters for that shard.
  def self.all
    Settings.repositories.storages.map do |name, params|
      config = params.symbolize_keys.merge(name: name, path: params.legacy_disk_path)
      config.slice!(*allowed_params)
      StorageShard.new(config)
    end
  end

  def self.allowed_params
    %i(name path).freeze
  end
end
