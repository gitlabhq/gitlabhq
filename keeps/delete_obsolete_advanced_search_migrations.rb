# frozen_string_literal: true

require 'rubocop'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. This keep will not make any changes unless there are
  # more than one obsolete Advanced search migrations. This keep will remove all but the most recent obsolete
  # migrations from the code.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d \
  #   -k Keeps::DeleteObsoleteAdvancedSearchMigrations
  # ```
  class DeleteObsoleteAdvancedSearchMigrations < ::Gitlab::Housekeeper::Keep
    MIGRATIONS_PATH = 'ee/elastic/migrate'
    MIGRATION_REGEXP = /\A([0-9]+)_([_a-z0-9]*)\.rb\z/
    MIGRATIONS_SPECS_PATH = 'ee/spec/elastic/migrate/'
    MIGRATION_DOCS_PATH = 'ee/elastic/docs'

    GROUP_LABEL = 'group::global search'

    def initialize(logger: nil)
      @obsolete_migrations_to_delete = {}
      load_migrations_to_process

      super(logger: logger)
    end

    def each_change
      return unless obsolete_migrations_to_delete.size > 1

      remove_obsolete_change = create_remove_obsolete_change
      yield(remove_obsolete_change) if remove_obsolete_change

      nil
    end

    private

    attr_reader :obsolete_migrations_to_delete

    def load_migrations_to_process
      each_advanced_search_migration do |migration_filename, spec_filename, yaml_content|
        version = yaml_content['version']
        next unless yaml_content['obsolete']

        obsolete_migrations_to_delete[version] = { file: migration_filename, spec_file: spec_filename }
      end
    end

    def get_migration_versions_from_codebase
      migration_files = Dir[File.join(MIGRATIONS_PATH, '**', '[0-9]*_*.rb')]
      migration_versions_hash = {}
      migration_files.each do |migration_file|
        version, filename = File.basename(migration_file).scan(MIGRATION_REGEXP).first
        migration_versions_hash[version] = { version: version, filename: filename }
      end
      migration_versions_hash
    end

    def each_advanced_search_migration
      all_advanced_search_migration_files.map do |f|
        version, filename = File.basename(f).scan(MIGRATION_REGEXP).first
        yaml_file = "#{MIGRATION_DOCS_PATH}/#{version}_#{filename}.yml"
        spec_file = "#{MIGRATIONS_SPECS_PATH}/#{version}_#{filename}_spec.rb"

        yield(f, spec_file, YAML.load_file(yaml_file))
      end
    end

    def all_advanced_search_migration_files
      Dir.glob("#{MIGRATIONS_PATH}/*.rb")
    end

    def create_remove_obsolete_change
      change = ::Gitlab::Housekeeper::Change.new
      change.title = 'Remove obsolete Advanced search migrations'
      change.identifiers = [self.class.name.demodulize, 'remove_obsolete']
      change.labels = [
        'maintenance::removal',
        GROUP_LABEL
      ]
      change.assignees = groups_helper.pick_reviewer(group_data, change.identifiers)
      change.changelog_ee = true

      # rubocop:disable Gitlab/DocumentationLinks/HardcodedUrl -- Not running inside rails application
      change.description = <<~MARKDOWN
        This migration removes all but the latest obsolete Advanced search migration files from the project.

        You can read more about the process for marking Advanced search migrations as obsolete in
        https://docs.gitlab.com/ee/development/search/advanced_search_migration_styleguide.html#deleting-advanced-search-migrations-in-a-major-version-upgrade.

        As part of our process, we want to ensure all obsolete Advanced search migrations have had at least one
        [required stop](https://docs.gitlab.com/ee/development/database/required_stops.html) as obsolete migrations
        before removing the migration code from the project. Therefore we can remove code for all Advanced search
        migrations that were made obsolete before the last required stop.

        ## Tasks to complete before merging

        - [ ] Update the archive of migrations in https://gitlab.com/gitlab-org/search-team/migration-graveyard
        - [ ] Remove references to affected migration or spec files from Rubocop TODOs
      MARKDOWN
      # rubocop:enable Gitlab/DocumentationLinks/HardcodedUrl

      change.changed_files = []
      # always leave one migration
      last_key = obsolete_migrations_to_delete.keys.max
      obsolete_migrations_to_delete.delete(last_key)
      obsolete_migrations_to_delete.each do |version, migration_data|
        FileUtils.rm_f(migration_data[:file])
        change.changed_files << migration_data[:file]

        if File.exist?(migration_data[:spec_file])
          FileUtils.rm_f(migration_data[:spec_file])
          change.changed_files << migration_data[:spec_file]
        end
      rescue StandardError => e
        warn "Error deleting #{version} migration and spec: #{e}"
        nil
      end

      change
    end

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def group_data
      @group_data ||= groups_helper.group_for_group_label(GROUP_LABEL)
    end
  end
end
