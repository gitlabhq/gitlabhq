# frozen_string_literal: true

module Quality
  class TestLevel
    UnknownTestLevelError = Class.new(StandardError)

    TEST_LEVEL_FOLDERS = {
      migration: %w[
        migrations
      ],
      background_migration: %w[
        lib/gitlab/background_migration
        lib/ee/gitlab/background_migration
      ],
      frontend_fixture: %w[
        frontend/fixtures
      ],
      unit: %w[
        bin
        channels
        config
        db
        dependencies
        elastic
        elastic_integration
        experiments
        factories
        finders
        frontend
        graphql
        haml_lint
        helpers
        initializers
        javascripts
        lib
        models
        policies
        presenters
        rack_servers
        replicators
        routing
        rubocop
        serializers
        services
        sidekiq
        spam
        support_specs
        tasks
        uploaders
        validators
        views
        workers
        tooling
      ],
      integration: %w[
        controllers
        mailers
        requests
      ],
      system: ['features']
    }.freeze

    attr_reader :prefix

    def initialize(prefix = nil)
      @prefix = prefix
      @patterns = {}
      @regexps = {}
    end

    def pattern(level)
      @patterns[level] ||= "#{prefix}spec/#{folders_pattern(level)}{,/**/}*#{suffix(level)}"
    end

    def regexp(level)
      @regexps[level] ||= Regexp.new("#{prefix}spec/#{folders_regex(level)}").freeze
    end

    def level_for(file_path)
      case file_path
      # Detect migration first since some background migration tests are under
      # spec/lib/gitlab/background_migration and tests under spec/lib are unit by default
      when regexp(:migration), regexp(:background_migration)
        :migration
      # Detect frontend fixture before matching other unit tests
      when regexp(:frontend_fixture)
        :frontend_fixture
      when regexp(:unit)
        :unit
      when regexp(:integration)
        :integration
      when regexp(:system)
        :system
      else
        raise UnknownTestLevelError, "Test level for #{file_path} couldn't be set. Please rename the file properly or change the test level detection regexes in #{__FILE__}."
      end
    end

    def background_migration?(file_path)
      !!(file_path =~ regexp(:background_migration))
    end

    private

    def suffix(level)
      case level
      when :frontend_fixture
        ".rb"
      else
        "_spec.rb"
      end
    end

    def migration_and_background_migration_folders
      TEST_LEVEL_FOLDERS.fetch(:migration) + TEST_LEVEL_FOLDERS.fetch(:background_migration)
    end

    def folders_pattern(level)
      case level
      when :migration
        "{#{migration_and_background_migration_folders.join(',')}}"
      # Geo specs aren't in a specific folder, but they all have the :geo tag, so we must search for them globally
      when :all, :geo
        '**'
      else
        "{#{TEST_LEVEL_FOLDERS.fetch(level).join(',')}}"
      end
    end

    def folders_regex(level)
      case level
      when :migration
        "(#{migration_and_background_migration_folders.join('|')})"
      # Geo specs aren't in a specific folder, but they all have the :geo tag, so we must search for them globally
      when :all, :geo
        ''
      else
        "(#{TEST_LEVEL_FOLDERS.fetch(level).join('|')})"
      end
    end
  end
end
