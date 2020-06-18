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
      unit: %w[
        bin
        channels
        config
        db
        dependencies
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
        support_specs
        tasks
        uploaders
        validators
        views
        workers
        elastic_integration
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
      @patterns[level] ||= "#{prefix}spec/#{folders_pattern(level)}{,/**/}*_spec.rb"
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

    def folders_pattern(level)
      case level
      # Geo specs aren't in a specific folder, but they all have the :geo tag, so we must search for them globally
      when :all, :geo
        '**'
      else
        "{#{TEST_LEVEL_FOLDERS.fetch(level).join(',')}}"
      end
    end

    def folders_regex(level)
      case level
      # Geo specs aren't in a specific folder, but they all have the :geo tag, so we must search for them globally
      when :all, :geo
        ''
      else
        "(#{TEST_LEVEL_FOLDERS.fetch(level).join('|')})"
      end
    end
  end
end
