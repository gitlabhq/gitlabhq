# frozen_string_literal: true

require 'rubocop'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. This keep will not make any changes unless there are
  # Advanced search migrations to be marked as obsolete. This keep locates advanced search migrations that were added
  # before the cutoff milestone and adds a prepend to the bottom of the migration file which marks the migration as
  # obsolete in the code. It also updates the corresponding `ee/elastic/migrate/docs/` file with
  # a `marked_obsolete_in_milestone`. The cutoff milestone is defined as one milestone before the last required stop.
  # This is to prevent long running migrations from being marked as obsolete.
  #
  # You can run it manually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::MarkOldAdvancedSearchMigrationsAsObsolete
  # ```
  class MarkOldAdvancedSearchMigrationsAsObsolete < ::Gitlab::Housekeeper::Keep
    MIGRATIONS_PATH = 'ee/elastic/migrate'
    MIGRATION_REGEXP = /\A([0-9]+)_([_a-z0-9]*)\.rb\z/
    MIGRATIONS_SPECS_PATH = 'ee/spec/elastic/migrate/'
    MIGRATION_DOCS_PATH = 'ee/elastic/docs'

    GROUP_LABEL = 'group::global search'

    def initialize(logger: nil)
      @migrations_to_be_marked_obsolete = {}
      @search_team_map = group_data['backend_engineers'].index_with(0)

      load_migrations_to_process

      super
    end

    def each_change
      return if migrations_to_be_marked_obsolete.empty?

      migrations_to_be_marked_obsolete.each do |version, migration_data|
        mark_obsolete_change = create_mark_obsolete_change(version, migration_data)
        next unless mark_obsolete_change

        search_team_map[mark_obsolete_change.assignees.first] += 1
        yield(mark_obsolete_change)
      end

      nil
    end

    private

    attr_reader :migrations_to_be_marked_obsolete, :search_team_map

    def load_migrations_to_process
      each_advanced_search_migration do |migration_filename, spec_filename, yaml_filename, yaml_content|
        version = yaml_content['version']
        next unless before_cutoff_milestone?(yaml_content['milestone'])
        next if yaml_content['obsolete']
        next unless before_cutoff_milestone?(yaml_content['milestone'])

        migrations_to_be_marked_obsolete[version] =
          {
            file: migration_filename,
            spec_file: spec_filename,
            yaml_filename: yaml_filename,
            yaml_content: yaml_content
          }
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

    def before_cutoff_milestone?(milestone)
      Gem::Version.new(milestone) < Gem::Version.new(cutoff_milestone)
    end

    def each_advanced_search_migration
      all_advanced_search_migration_files.map do |f|
        version, filename = File.basename(f).scan(MIGRATION_REGEXP).first
        yaml_file = "#{MIGRATION_DOCS_PATH}/#{version}_#{filename}.yml"
        spec_file = "#{MIGRATIONS_SPECS_PATH}/#{version}_#{filename}_spec.rb"

        yield(f, spec_file, yaml_file, YAML.load_file(yaml_file))
      end
    end

    def all_advanced_search_migration_files
      Dir.glob("#{MIGRATIONS_PATH}/*.rb")
    end

    def create_mark_obsolete_change(version, migration_data)
      migration_name = migration_data[:yaml_content]['name']
      change = ::Gitlab::Housekeeper::Change.new
      change.title = "Mark #{version} as obsolete"
      change.identifiers = ['mark_obsolete', version, migration_name]
      change.labels = [
        'maintenance::refactor',
        GROUP_LABEL
      ]
      assignee = search_team_map.min_by { |_k, v| v }.first
      change.assignees = assignee
      change.changelog_ee = true

      # rubocop:disable Gitlab/DocumentationLinks/HardcodedUrl -- Not running inside rails application
      change.description = <<~MARKDOWN
        This migration marks the #{version} #{migration_name} Advanced search migration as obsolete.

        [Search for references to `#{migration_name.underscore}` in code](https://gitlab.com/search?project_id=278964&scope=blobs&search=#{migration_name.underscore}&regex=false))

        At the moment, the `gitlab-housekeeper` is not always capable of removing all references so
        you must check the diff and pipeline failures to confirm if there are any issues.
        It is the responsibility of the assignee (picked from ~"group::global search") to push those changes to this branch.

        [Read more](https://docs.gitlab.com/ee/development/search/advanced_search_migration_styleguide.html#cleaning-up-advanced-search-migrations)
        about the process for marking Advanced search migrations as obsolete.

        All Advanced search migrations must have had at least one
        [required stop](https : // docs.gitlab.com / ee / development / database / required_stops.html)
        to process the migration. Therefore we mark any Advanced search migrations added before the
        last required stop as obsolete.
      MARKDOWN
      # rubocop:enable Gitlab/DocumentationLinks/HardcodedUrl

      change.changed_files = []
      add_obsolete_to_yaml(migration_data[:yaml_filename], migration_data[:yaml_content])
      change.changed_files << migration_data[:yaml_filename]

      add_obsolete_to_migration(migration_data[:file])
      change.changed_files << migration_data[:file]

      if File.exist?(migration_data[:spec_file])
        add_obsolete_to_migration_spec(version, migration_data[:spec_file], migration_data[:yaml_content]['name'])
        change.changed_files << migration_data[:spec_file]
      end

      change.push_options.ci_skip = true

      change
    end

    def add_obsolete_to_yaml(file, content)
      content['obsolete'] = true
      content['marked_obsolete_in_milestone'] = migration_marked_as_obsolete_milestone.to_s
      File.open(file, 'w') { |f| f.write(YAML.dump(content)) }
    end

    def add_obsolete_to_migration(file)
      source = RuboCop::ProcessedSource.new(File.read(file), RuboCop::ConfigStore.new.for_file('.').target_ruby_version)
      ast = source.ast
      klass_name = ast.children[0].source

      File.open(file, 'a') { |f| f.write("\n#{klass_name}.prepend ::Elastic::MigrationObsolete\n") }
    end

    def add_obsolete_to_migration_spec(version, file, name)
      source = RuboCop::ProcessedSource.new(File.read(file), RuboCop::ConfigStore.new.for_file('.').target_ruby_version)
      rewriter = Parser::Source::TreeRewriter.new(source.buffer)
      describe_block = source.ast.each_node(:block).first
      content = <<~RUBY.strip
        RSpec.describe #{name}, feature_category: :global_search do
          it_behaves_like 'a deprecated Advanced Search migration', #{version}
        end
      RUBY

      rewriter.replace(describe_block.loc.expression, content)
      process = rewriter.process.lstrip.gsub(/\n{3,}/, "\n\n")

      File.write(file, process)
    end

    def migration_marked_as_obsolete_milestone
      @migration_marked_as_obsolete_milestone ||= read_milestone
    end

    def read_milestone
      milestone = File.read('VERSION')
      milestone.gsub(/^(\d+\.\d+).*$/, '\1').chomp
    end

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def group_data
      @group_data ||= groups_helper.group_for_group_label(GROUP_LABEL)
    end

    def cutoff_milestone
      @cutoff_milestone ||= calculate_cutoff_milestone
    end

    def calculate_cutoff_milestone
      # Only mark migrations added in the milestone before the last required stop as obsolete
      last_required_stop = Gitlab::Database.min_schema_gitlab_version

      if last_required_stop.minor > 0
        Gitlab::VersionInfo.new(last_required_stop.major, last_required_stop.minor - 1, 0)
      else
        Gitlab::VersionInfo.new(last_required_stop.major - 1, 11, 0)
      end
    end
  end
end
