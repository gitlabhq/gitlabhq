# frozen_string_literal: true

module Backup
  class Metadata
    # Fullpath for the manifest file
    # @return [Pathname] full path for the manifest file
    attr_reader :manifest_filepath

    # Information present in the manifest file shipped along with the backup
    # @return [BackupInformation]
    attr_reader :backup_information

    YAML_PERMITTED_CLASSES = [
      ActiveSupport::TimeWithZone, ActiveSupport::TimeZone, Symbol, Time
    ].freeze

    # Backup Manifest content, describing what the backup contains and the environment in which it was created
    # Includes versions information, timestamp, installation type and other data required to restore or to
    # keep incremental backups working
    BackupInformation = Struct.new(
      :db_version, # ActiveRecord::Migrator.current_version.to_s,
      :backup_created_at, # Time.current,
      :gitlab_version, # Gitlab::VERSION,
      :tar_version, # tar_version,
      :installation_type, # Gitlab::INSTALLATION_TYPE,
      :skipped, # ENV['SKIP']
      :repositories_storages, # ENV['REPOSITORIES_STORAGES'],
      :repositories_paths, # ENV['REPOSITORIES_PATHS'],
      :skip_repositories_paths, # ENV['SKIP_REPOSITORIES_PATHS'],
      :repositories_server_side, # Gitlab::Utils.to_boolean(ENV['REPOSITORIES_SERVER_SIDE'], default: false)
      :backup_id, # ENV['BACKUP'] or calculated based on backup_created_at and Gitlab::VERSION
      :full_backup_id, # full_backup_id,
      keyword_init: true
    )

    def initialize(manifest_filepath)
      @manifest_filepath = Pathname.new(manifest_filepath)
    end

    # Load #BackupInformation from a YAML manifest file on disk
    def load!
      return @backup_information unless @backup_information.nil?

      manifest_data = load_from_file

      @backup_information = BackupInformation.new(**manifest_data)
    end

    # Save content from #BackupInformation into a manifest YAML file on disk
    def save!
      Dir.chdir(File.dirname(manifest_filepath)) do
        File.open(manifest_filepath, 'w+') do |file|
          file << backup_information.to_h.to_yaml.gsub(/^---\n/, '')
        end
      end
    end

    # Update backup information with provided data
    #
    # @param [Hash] data arguments matching #BackupInformation keyword arguments
    def update(**data)
      @backup_information ||= BackupInformation.new

      data.each_pair do |key, value|
        backup_information[key] = value
      end
    end

    private

    def load_from_file
      YAML.safe_load_file(
        manifest_filepath,
        permitted_classes: YAML_PERMITTED_CLASSES)
    end
  end
end
