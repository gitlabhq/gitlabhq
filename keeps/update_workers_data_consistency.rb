# frozen_string_literal: true

require_relative '../rubocop/cop_todo'

module Keeps
  # This is an implementation of ::Gitlab::Housekeeper::Keep.
  # This changes workers which have `data_consistency: :always` to `:sticky`.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::UpdateWorkersDataConsistency
  # ```
  class UpdateWorkersDataConsistency < ::Gitlab::Housekeeper::Keep
    WORKER_REGEX = %r{app/workers/(.+).rb}
    WORKERS_DATA_CONSISTENCY_PATH = '.rubocop_todo/sidekiq_load_balancing/worker_data_consistency.yml'
    FALLBACK_FEATURE_CATEGORY = 'database'
    LIMIT_TO = 5

    def initialize(...)
      ::Keeps::Helpers::FileHelper.def_node_matcher :data_consistency_node, <<~PATTERN
          `(send nil? :data_consistency $(sym _) ...)
      PATTERN

      super
    end

    def each_change
      workers_by_feature_category.deep_dup.each do |feature_category, workers|
        remove_workers_from_list(workers.pluck(:path)) # rubocop:disable CodeReuse/ActiveRecord -- small dataset

        workers.each do |worker|
          file_helper = ::Keeps::Helpers::FileHelper.new(worker[:path])
          node = file_helper.data_consistency_node
          File.write(worker[:path], file_helper.replace_as_string(node, ':sticky'))
        end

        yield(build_change(feature_category, workers))
      end
    end

    private

    def workers_by_feature_category
      worker_paths.each_with_object(Hash.new { |h, k| h[k] = [] }) do |worker_path, group|
        next unless File.read(worker_path, mode: 'rb').include?('data_consistency :always')

        worker_name = worker_path.match(WORKER_REGEX)[1].camelize

        feature_category = worker_feature_category(worker_name)

        next if group[feature_category].size >= LIMIT_TO

        group[feature_category] << { path: worker_path, name: worker_name }
      end
    end

    def build_change(feature_category, workers)
      change = ::Gitlab::Housekeeper::Change.new
      change.title = "Change data consistency for workers maintained by #{feature_category}".truncate(70, omission: '')
      change.identifiers = workers.map { |worker| worker[:name].to_s }.prepend(feature_category)
      change.labels = labels(feature_category)
      change.reviewers = pick_reviewers(feature_category, change.identifiers)
      change.changed_files = workers.pluck(:path).prepend(WORKERS_DATA_CONSISTENCY_PATH) # rubocop:disable CodeReuse/ActiveRecord -- small dataset

      change.description = <<~MARKDOWN.chomp
        ## What does this MR

        It updates workers data consistency from `:always` to `:sticky` for workers maintained by `#{feature_category}`,
        as a way to reduce database reads on the primary DB. Check https://gitlab.com/gitlab-org/gitlab/-/issues/462611.

        To reduce resource saturation on the primary node, all workers should be changed to `sticky`, at minimum.

        Since jobs are now enqueued along with the current database LSN, the replica (for `:sticky` or `:delayed`)
        is guaranteed to be caught up to that point, or the job will be retried, or use the primary. Consider updating
        the worker(s) to `delayed`, if it's applicable.

        You can read more about the Sidekiq Workers `data_consistency` in
        https://docs.gitlab.com/ee/development/sidekiq/worker_attributes.html#job-data-consistency-strategies.

        You can use this [dashboard](https://log.gprd.gitlab.net/app/r/s/iyIUV) to monitor the worker query activity on
        primary vs. replicas.

        Currently, the `gitlab-housekeeper` is not always capable of updating all references, so you must check the diff
        and pipeline failures to confirm if there are any issues.
      MARKDOWN

      change
    end

    def labels(feature_category)
      group_labels = groups_helper.labels_for_feature_category(feature_category)

      group_labels + %w[maintenance::scalability type::maintenance severity::3 priority::1]
    end

    def pick_reviewers(feature_category, identifiers)
      groups_helper.pick_reviewer_for_feature_category(
        feature_category,
        identifiers,
        fallback_feature_category: 'database'
      )
    end

    def worker_feature_category(worker_name)
      feature_category = workers_meta.find { |entry| entry[:worker_name].to_s == worker_name.to_s } || {}

      feature_category.fetch(:feature_category, FALLBACK_FEATURE_CATEGORY).to_s
    end

    def workers_meta
      @workers_meta ||= Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS.flat_map do |yaml_file|
        YAML.safe_load_file(yaml_file, permitted_classes: [Symbol])
      end
    end

    def remove_workers_from_list(paths_to_remove)
      todo_helper = RuboCop::CopTodo.new('SidekiqLoadBalancing/WorkerDataConsistency')
      todo_helper.add_files(worker_paths - paths_to_remove)

      File.write(WORKERS_DATA_CONSISTENCY_PATH, todo_helper.to_yaml)
    end

    def worker_paths
      @worker_paths ||= YAML.safe_load_file(WORKERS_DATA_CONSISTENCY_PATH).dig(
        'SidekiqLoadBalancing/WorkerDataConsistency',
        'Exclude'
      )
    end

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end
  end
end
