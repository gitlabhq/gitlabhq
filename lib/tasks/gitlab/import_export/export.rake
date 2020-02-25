# frozen_string_literal: true

require 'gitlab/with_request_store'

# Export project to archive
#
# @example
#   bundle exec rake "gitlab:import_export:export[root, root, project_to_export, /path/to/file.tar.gz, true]"
#
namespace :gitlab do
  namespace :import_export do
    desc 'GitLab | Import/Export | EXPERIMENTAL | Export large project archives'
    task :export, [:username, :namespace_path, :project_path, :archive_path, :measurement_enabled] => :gitlab_environment do |_t, args|
      # Load it here to avoid polluting Rake tasks with Sidekiq test warnings
      require 'sidekiq/testing'

      warn_user_is_not_gitlab

      if ENV['IMPORT_DEBUG'].present?
        ActiveRecord::Base.logger = Logger.new(STDOUT)
        Gitlab::Metrics::Exporter::SidekiqExporter.instance.start
      end

      GitlabProjectExport.new(
        namespace_path: args.namespace_path,
        project_path:   args.project_path,
        username:       args.username,
        file_path:      args.archive_path,
        measurement_enabled: Gitlab::Utils.to_boolean(args.measurement_enabled)
      ).export
    end
  end
end

class GitlabProjectExport
  include Gitlab::WithRequestStore

  def initialize(opts)
    @project_path = opts.fetch(:project_path)
    @file_path = opts.fetch(:file_path)
    @current_user = User.find_by_username(opts.fetch(:username))
    namespace = Namespace.find_by_full_path(opts.fetch(:namespace_path))
    @project = namespace.projects.find_by_path(@project_path)
    @measurement_enabled = opts.fetch(:measurement_enabled)
    @measurable = Gitlab::Utils::Measuring.new if @measurement_enabled
  end

  def export
    validate_project
    validate_file_path

    with_export do
      ::Projects::ImportExport::ExportService.new(project, current_user)
        .execute(Gitlab::ImportExport::AfterExportStrategies::MoveFileStrategy.new(archive_path: file_path))
    end

    puts 'Done!'
  rescue StandardError => e
    puts "Exception: #{e.message}"
    puts e.backtrace
    exit 1
  end

  private

  attr_reader :measurable, :project, :current_user, :file_path, :project_path

  def validate_project
    unless project
      puts "Error: Project with path: #{project_path} was not found. Please provide correct project path"
      exit 1
    end
  end

  def validate_file_path
    directory = File.dirname(file_path)
    unless Dir.exist?(directory)
      puts "Error: Invalid file path: #{file_path}. Please provide correct file path"
      exit 1
    end
  end

  def with_export
    with_request_store do
      ::Gitlab::GitalyClient.allow_n_plus_1_calls do
        measurement_enabled? ? measurable.with_measuring { yield } : yield
      end
    end
  end

  def measurement_enabled?
    @measurement_enabled
  end
end
