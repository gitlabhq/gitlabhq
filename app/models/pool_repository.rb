# frozen_string_literal: true

# The PoolRepository model is the database equivalent of an ObjectPool for Gitaly
# That is; PoolRepository is the record in the database, ObjectPool is the
# repository on disk
class PoolRepository < ApplicationRecord
  include Shardable
  include AfterCommitQueue

  belongs_to :source_project, class_name: 'Project'

  has_many :member_projects, class_name: 'Project'

  after_create :set_disk_path

  scope :by_source_project, ->(project) { where(source_project: project) }
  scope :by_disk_path, ->(disk_path) { where(disk_path: disk_path) }
  scope :by_disk_path_and_shard_name, ->(disk_path, shard_name) do
    by_disk_path(disk_path)
      .for_repository_storage(shard_name)
  end

  state_machine :state, initial: :none do
    state :scheduled
    state :ready
    state :failed
    state :obsolete

    event :schedule do
      transition none: :scheduled
    end

    event :mark_ready do
      transition [:scheduled, :failed] => :ready
    end

    event :mark_failed do
      transition all => :failed
    end

    event :mark_obsolete do
      transition all => :obsolete
    end

    state all - [:ready] do
      def joinable?
        false
      end
    end

    state :ready do
      def joinable?
        true
      end
    end

    after_transition none: :scheduled do |pool, _|
      pool.run_after_commit do
        ::ObjectPool::CreateWorker.perform_async(pool.id)
      end
    end

    after_transition scheduled: :ready do |pool, _|
      pool.run_after_commit do
        ::ObjectPool::ScheduleJoinWorker.perform_async(pool.id)
      end
    end

    after_transition any => :obsolete do |pool, _|
      pool.run_after_commit do
        ::ObjectPool::DestroyWorker.perform_async(pool.id)
      end
    end
  end

  def create_object_pool
    object_pool.create
  rescue GRPC::AlreadyExists
    # The object pool already exists. Nothing to do here.
  end

  # The members of the pool should have fetched the missing objects to their own
  # objects directory. If the caller fails to do so, data loss might occur
  def delete_object_pool
    object_pool.delete
  end

  def link_repository(repository)
    object_pool.link(repository.raw)
  end

  def unlink_repository(repository, disconnect: true)
    repository.disconnect_alternates if disconnect

    if member_projects.where.not(id: repository.project.id).exists?
      true
    else
      mark_obsolete
    end
  end

  def object_pool
    @object_pool ||= Gitlab::Git::ObjectPool.new(
      shard.name,
      disk_path + '.git',
      source_project&.repository&.raw,
      source_project&.full_path
    )
  end

  def inspect
    source = source_project ? source_project.full_path : 'nil'
    "#<#{self.class.name} id:#{id} state:#{state} disk_path:#{disk_path} source_project: #{source}>"
  end

  private

  def set_disk_path
    update!(disk_path: storage.disk_path) if disk_path.blank?
  end

  def storage
    Storage::Hashed
      .new(self, prefix: Storage::Hashed::POOL_PATH_PREFIX)
  end
end

PoolRepository.prepend_mod_with('PoolRepository')
