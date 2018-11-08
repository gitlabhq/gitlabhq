# frozen_string_literal: true

class PoolRepository < ActiveRecord::Base
  POOL_PREFIX = '@pools'

  belongs_to :shard
  validates :shard, presence: true

  # For now, only pool repositories are tracked in the database. However, we may
  # want to add other repository types in the future
  self.table_name = 'repositories'

  has_many :pool_member_projects, class_name: 'Project', foreign_key: :pool_repository_id

  def shard_name
    shard&.name
  end

  def shard_name=(name)
    self.shard = Shard.by_name(name)
  end
end
