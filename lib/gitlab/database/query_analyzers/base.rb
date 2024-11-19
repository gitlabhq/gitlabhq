# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class Base
        # `Exception` to ensure that is not easily rescued when running in test env
        QueryAnalyzerError = Class.new(Exception) # rubocop:disable Lint/InheritException

        def self.suppressed?
          Thread.current[self.suppress_key] || @suppress_in_rspec
        end

        def self.requires_tracking?(parsed)
          false
        end

        def self.suppress=(value)
          Thread.current[self.suppress_key] = value
        end

        # The other suppress= method stores the
        # value in Thread.current because it is
        # meant to work in a multi-threaded puma
        # environment but this does not work
        # correctly in capybara tests where we
        # suppress in the rspec runner context but
        # this does not take effect in the puma
        # thread. As such we just suppress
        # globally in RSpec since we don't run
        # different tests concurrently.
        class << self
          attr_writer :suppress_in_rspec
        end

        # During database decomposition, db migrations using tables that will be decomposed
        # will begin to contravene their configuration for intended gitlab_schema and database connection.
        # As these migrations already exist, ideally they should be finalized and removed prior to decomposition.
        # In this situations, it's necessary to suppress warnings related to their incorrect connection and schema
        # to progress our CI pipelines.
        def self.suppress_schema_issues_for_decomposed_tables
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
            Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
              yield
            end
          end
        end

        def self.with_suppressed(value = true, &blk)
          previous = self.suppressed?
          self.suppress = value
          yield
        ensure
          self.suppress = previous
        end

        def self.begin!
          Thread.current[self.context_key] = {}
        end

        def self.end!
          Thread.current[self.context_key] = nil
        end

        def self.context
          Thread.current[self.context_key]
        end

        def self.enabled?
          raise NotImplementedError
        end

        def self.analyze(parsed)
          raise NotImplementedError
        end

        def self.context_key
          @context_key ||= "analyzer_#{self.analyzer_key}_context".to_sym
        end

        def self.suppress_key
          @suppress_key ||= "analyzer_#{self.analyzer_key}_suppressed".to_sym
        end

        def self.analyzer_key
          @analyzer_key ||= self.name.demodulize.underscore.to_sym
        end
      end
    end
  end
end
