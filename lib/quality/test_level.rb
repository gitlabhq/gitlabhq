# frozen_string_literal: true

module Quality
  class TestLevel
    UnknownTestLevelError = Class.new(StandardError)

    TEST_LEVEL_FOLDERS = {
      unit: %w[
        bin
        config
        db
        dependencies
        factories
        finders
        frontend
        graphql
        helpers
        initializers
        javascripts
        lib
        migrations
        models
        policies
        presenters
        rack_servers
        routing
        rubocop
        serializers
        services
        sidekiq
        tasks
        uploaders
        validators
        views
        workers
        elastic_integration
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
      @patterns[level] ||= "#{prefix}spec/{#{TEST_LEVEL_FOLDERS.fetch(level).join(',')}}{,/**/}*_spec.rb".freeze
    end

    def regexp(level)
      @regexps[level] ||= Regexp.new("#{prefix}spec/(#{TEST_LEVEL_FOLDERS.fetch(level).join('|')})").freeze
    end

    def level_for(file_path)
      case file_path
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
  end
end
