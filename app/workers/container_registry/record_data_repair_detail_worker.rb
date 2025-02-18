# frozen_string_literal: true

module ContainerRegistry
  class RecordDataRepairDetailWorker
    include ApplicationWorker
    include CronjobChildWorker
    include ExclusiveLeaseGuard
    include LimitedCapacity::Worker
    include Gitlab::Utils::StrongMemoize

    data_consistency :always
    queue_namespace :container_repository
    feature_category :container_registry
    urgency :low
    worker_resource_boundary :unknown
    idempotent!

    LEASE_TIMEOUT = 1.hour.to_i

    def perform_work
      return unless Gitlab.com_except_jh?
      return unless next_project
      return if next_project.container_registry_data_repair_detail

      missing_count = 0

      try_obtain_lease do
        detail = create_data_repair_detail

        GitlabApiClient.each_sub_repositories_with_tag_page(path: next_project.full_path,
          page_size: 50) do |repositories|
          next if repositories.empty?

          paths = repositories.map { |repo| ContainerRegistry::Path.new(repo["path"]) }
          paths, invalid_paths = paths.partition(&:valid?)
          unless invalid_paths.empty?
            log_extra_metadata_on_done(
              :invalid_paths_parsed_in_container_repository_repair,
              invalid_paths.join(' ,')
            )
          end

          found_repositories = next_project.container_repositories.where(name: paths.map(&:repository_name)) # rubocop:disable CodeReuse/ActiveRecord

          missing_count += repositories.count - found_repositories.count
        end
        detail.update!(missing_count: missing_count, status: :completed)
      end
    rescue StandardError => exception
      next_project.reset.container_registry_data_repair_detail&.update(status: :failed)
      Gitlab::ErrorTracking.log_exception(exception, class: self.class.name)
    end

    def remaining_work_count
      return 0 unless Gitlab.com_except_jh?
      return 0 unless Feature.enabled?(:registry_data_repair_worker)
      return 0 unless ContainerRegistry::GitlabApiClient.supports_gitlab_api?

      Project.pending_data_repair_analysis.limit(max_running_jobs + 1).count
    end

    def max_running_jobs
      current_application_settings.container_registry_data_repair_detail_worker_max_concurrency.to_i
    end

    private

    def current_application_settings
      ::Gitlab::CurrentSettings.current_application_settings
    end

    def next_project
      Project.pending_data_repair_analysis.limit(max_running_jobs * 2).sample
    end
    strong_memoize_attr :next_project

    def create_data_repair_detail
      ContainerRegistry::DataRepairDetail.create!(project: next_project, status: :ongoing)
    end

    # Used by ExclusiveLeaseGuard
    def lease_key
      "container_registry_data_repair_detail_worker:#{next_project.id}"
    end

    # Used by ExclusiveLeaseGuard
    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
