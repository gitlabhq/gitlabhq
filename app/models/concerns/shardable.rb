# frozen_string_literal: true

module Shardable
  extend ActiveSupport::Concern

  included do
    belongs_to :shard

    scope :for_repository_storage, ->(repository_storage) { joins(:shard).where(shards: { name: repository_storage }) }
    scope :excluding_repository_storage, ->(repository_storage) { joins(:shard).where.not(shards: { name: repository_storage }) }
    scope :for_shard, ->(shard) { where(shard_id: shard) }

    validates :shard, presence: true
  end

  def shard_name
    shard&.name
  end

  def shard_name=(name)
    self.shard = Shard.by_name(name)
  end
end
