# frozen_string_literal: true

module Shardable
  extend ActiveSupport::Concern

  included do
    belongs_to :shard
    validates :shard, presence: true
  end

  def shard_name
    shard&.name
  end

  def shard_name=(name)
    self.shard = Shard.by_name(name)
  end
end
