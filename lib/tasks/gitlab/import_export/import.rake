# frozen_string_literal: true

require 'gitlab/with_request_store'

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
        measurement_enabled: Gitlab::Utils.to_boolean(args.measurement_enabled)
      ).import
    end
  end
end

class GitlabProjectImport
  include Gitlab::WithRequestStore

  def initialize(opts)
    @project_path = opts.fetch(:project_path)
    @file_path    = opts.fetch(:file_path)
    @namespace    = Namespace.find_by_full_path(opts.fetch(:namespace_path))
    @current_user = User.find_by_username(opts.fetch(:username))
    @measurement_enabled = opts.fetch(:measurement_enabled)
    @measurement = Gitlab::Utils::Measuring.new if @measurement_enabled
  end

  def import
    show_import_start_message

    run_isolated_sidekiq_job

    show_import_failures_count

    if project&.import_state&.last_error
      puts "ERROR: #{project.import_state.last_error}"
      exit 1
    elsif project.errors.any?
      puts "ERROR: #{project.errors.full_messages.join(', ')}"
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

  attr_reader :measurement, :project, :namespace, :current_user, :file_path, :project_path

  def measurement_enabled?
    @measurement_enabled
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
          measurement_enabled? ? measurement.with_measuring { yield } : yield
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
        current_user,
        {
          namespace_id: namespace.id,
          path:         project_path,
          file:         File.open(file_path)
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
    "#{namespace.full_path}/#{project_path}"
  end

  def show_import_start_message
    puts "Importing GitLab export: #{file_path} into GitLab" \
      " #{full_path}" \
      " as #{current_user.name}"
  end

  def show_import_failures_count
    return unless project.import_failures.exists?

    puts "Total number of not imported relations: #{project.import_failures.count}"
  end
end
