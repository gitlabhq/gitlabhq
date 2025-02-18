# frozen_string_literal: true

class NamespaceStatistics < ApplicationRecord # rubocop:disable Gitlab/NamespacedClass
  include AfterCommitQueue

  belongs_to :namespace

  validates :namespace, presence: true

  scope :for_namespaces, ->(namespaces) { where(namespace: namespaces) }

  before_save :update_storage_size
  after_destroy :update_root_storage_statistics
  after_save :update_root_storage_statistics, if: :saved_change_to_storage_size?

  delegate :group_namespace?, to: :namespace

  def refresh!(only: [])
    return if Gitlab::Database.read_only?
    return unless group_namespace?

    self.class.columns_to_refresh.each do |column|
      if only.empty? || only.include?(column)
        public_send("update_#{column}") # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    save!
  end

  def update_storage_size
    # This prevents failures with older database schemas, such as those
    # in migration specs.
    return unless self.class.database.cached_column_exists?(:dependency_proxy_size)

    self.storage_size = dependency_proxy_size
  end

  def update_dependency_proxy_size
    return unless group_namespace?

    self.dependency_proxy_size = [
      namespace.dependency_proxy_manifests,
      namespace.dependency_proxy_blobs,
      ::VirtualRegistries::Packages::Maven::Cache::Entry.for_group(namespace)
    ].sum { |rel| rel.sum(:size) }
  end

  def self.columns_to_refresh
    [:dependency_proxy_size]
  end

  private

  def update_root_storage_statistics
    return unless group_namespace?

    run_after_commit do
      Namespaces::ScheduleAggregationWorker.perform_async(namespace.id)
    end
  end
end

NamespaceStatistics.prepend_mod_with('NamespaceStatistics')
