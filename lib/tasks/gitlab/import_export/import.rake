# frozen_string_literal: true

# Import large project archives
#
# This task:
#   1. Disables ObjectStorage for archive upload
#   2. Performs Sidekiq job synchronously
#
# @example
#   bundle exec rake "gitlab:import_export:import[root, root, imported_project, /path/to/file.tar.gz, true]"
#
namespace :gitlab do
  namespace :import_export do
    desc 'GitLab | Import/Export | EXPERIMENTAL | Import large project archives'
    task :import, [:username, :namespace_path, :project_path, :archive_path, :measurement_enabled] => :gitlab_environment do |_t, args|
      # Load it here to avoid polluting Rake tasks with Sidekiq test warnings
      require 'sidekiq/testing'

      warn_user_is_not_gitlab

      if ENV['IMPORT_DEBUG'].present?
        ActiveRecord::Base.logger = Logger.new(STDOUT)
      end

      GitlabProjectImport.new(
        namespace_path: args.namespace_path,
        project_path:   args.project_path,
        username:       args.username,
        file_path:      args.archive_path,
        measurement_enabled: args.measurement_enabled == 'true'
      ).import
    end
  end
end

class GitlabProjectImport
  def initialize(opts)
    @project_path = opts.fetch(:project_path)
    @file_path    = opts.fetch(:file_path)
    @namespace    = Namespace.find_by_full_path(opts.fetch(:namespace_path))
    @current_user = User.find_by_username(opts.fetch(:username))
    @measurement_enabled = opts.fetch(:measurement_enabled)
  end

  def import
    show_import_start_message

    run_isolated_sidekiq_job

    show_import_failures_count

    if @project&.import_state&.last_error
      puts "ERROR: #{@project.import_state.last_error}"
      exit 1
    elsif @project.errors.any?
      puts "ERROR: #{@project.errors.full_messages.join(', ')}"
      exit 1
    else
      puts 'Done!'
    end
  rescue StandardError => e
    puts "Exception: #{e.message}"
    puts e.backtrace
    exit 1
  end

  private

  def with_request_store
    RequestStore.begin!
    yield
  ensure
    RequestStore.end!
    RequestStore.clear!
  end

  def with_count_queries(&block)
    count = 0

    counter_f = ->(name, started, finished, unique_id, payload) {
      unless payload[:name].in? %w[CACHE SCHEMA]
        count += 1
      end
    }

    ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)

    puts "Number of sql calls: #{count}"
  end

  def with_gc_counter
    gc_counts_before = GC.stat.select { |k, v| k =~ /count/ }
    yield
    gc_counts_after = GC.stat.select { |k, v| k =~ /count/ }
    stats = gc_counts_before.merge(gc_counts_after) { |k, vb, va| va - vb }
    puts "Total GC count: #{stats[:count]}"
    puts "Minor GC count: #{stats[:minor_gc_count]}"
    puts "Major GC count: #{stats[:major_gc_count]}"
  end

  def with_measure_time
    timing = Benchmark.realtime do
      yield
    end

    time = Time.at(timing).utc.strftime("%H:%M:%S")
    puts "Time to finish: #{time}"
  end

  def with_measuring
    puts "Measuring enabled..."
    with_gc_counter do
      with_count_queries do
        with_measure_time do
          yield
        end
      end
    end
  end

  def measurement_enabled?
    @measurement_enabled != false
  end

  # We want to ensure that all Sidekiq jobs are executed
  # synchronously as part of that process.
  # This ensures that all expensive operations do not escape
  # to general Sidekiq clusters/nodes.
  def with_isolated_sidekiq_job
    Sidekiq::Testing.fake! do
      with_request_store do
        # If you are attempting to import a large project into a development environment,
        # you may see Gitaly throw an error about too many calls or invocations.
        # This is due to a n+1 calls limit being set for development setups (not enforced in production)
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24475#note_283090635
        # For development setups, this code-path will be excluded from n+1 detection.
        ::Gitlab::GitalyClient.allow_n_plus_1_calls do
          measurement_enabled? ? with_measuring { yield } : yield
        end
      end

      true
    end
  end

  def run_isolated_sidekiq_job
    with_isolated_sidekiq_job do
      @project = create_project

      execute_sidekiq_job
    end
  end

  def create_project
    # We are disabling ObjectStorage for `import`
    # as it is too slow to handle big archives:
    # 1. DB transaction timeouts on upload
    # 2. Download of archive before unpacking
    disable_upload_object_storage do
      service = Projects::GitlabProjectsImportService.new(
        @current_user,
        {
          namespace_id: @namespace.id,
          path:         @project_path,
          file:         File.open(@file_path)
        }
      )

      service.execute
    end
  end

  def execute_sidekiq_job
    Sidekiq::Worker.drain_all
  end

  def disable_upload_object_storage
    overwrite_uploads_setting('background_upload', false) do
      overwrite_uploads_setting('direct_upload', false) do
        yield
      end
    end
  end

  def overwrite_uploads_setting(key, value)
    old_value = Settings.uploads.object_store[key]
    Settings.uploads.object_store[key] = value

    yield

  ensure
    Settings.uploads.object_store[key] = old_value
  end

  def full_path
    "#{@namespace.full_path}/#{@project_path}"
  end

  def show_import_start_message
    puts "Importing GitLab export: #{@file_path} into GitLab" \
      " #{full_path}" \
      " as #{@current_user.name}"
  end

  def show_import_failures_count
    return unless @project.import_failures.exists?

    puts "Total number of not imported relations: #{@project.import_failures.count}"
  end
end
