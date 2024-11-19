#!/usr/bin/env ruby
# frozen_string_literal: true

# We need to take some precautions when using the `gitlab` gem in this project.
#
# See https://docs.gitlab.com/ee/development/pipelines/internals.html#using-the-gitlab-ruby-gem-in-the-canonical-project.
#
# In spec/scripts/setup/generate_as_if_foss_env_spec.rb we completely stub it
if Object.const_defined?(:RSpec)
  # Ok, we're testing, we know we're going to stub `Gitlab`, so we just ignore
else
  require 'gitlab'

  if Gitlab.singleton_class.method_defined?(:com?)
    abort 'lib/gitlab.rb is loaded, and this means we can no longer load the client and we cannot proceed'
  end
end

class GenerateAsIfFossEnv
  PARALLEL = %r{(?: \d+/\d+)}
  PG_JOB = %r{\S+ pg\d+}

  # Map job names to environment variables. One job can match multiple variables.
  # For example: "rspec unit 1/2" returns `ENABLE_RSPEC` and `ENABLE_RSPEC_UNIT`.
  JOB_VARIABLES = {
    'build-assets-image' => 'ENABLE_BUILD_ASSETS_IMAGE',
    'build-qa-image' => 'ENABLE_BUILD_QA_IMAGE',
    'compile-production-assets' => 'ENABLE_COMPILE_PRODUCTION_ASSETS',
    'compile-storybook' => 'ENABLE_COMPILE_STORYBOOK',
    'compile-test-assets' => 'ENABLE_COMPILE_TEST_ASSETS',
    'detect-tests' => 'ENABLE_DETECT_TESTS',
    'eslint' => 'ENABLE_ESLINT',
    'generate-apollo-graphql-schema' => 'ENABLE_GENERATE_APOLLO_GRAPHQL_SCHEMA',
    'graphql-schema-dump' => 'ENABLE_GRAPHQL_SCHEMA_DUMP',
    'rspec-predictive:pipeline-generate' => 'ENABLE_RSPEC_PREDICTIVE_PIPELINE_GENERATE',
    'rspec:predictive:trigger' => 'ENABLE_RSPEC_PREDICTIVE_TRIGGER',
    'rspec:predictive:trigger single-db' => 'ENABLE_RSPEC_PREDICTIVE_TRIGGER_SINGLE_DB',
    'rspec:predictive:trigger single-db-ci-connection' => 'ENABLE_RSPEC_PREDICTIVE_TRIGGER_SINGLE_DB_CI_CONNECTION',
    'rubocop' => 'ENABLE_RUBOCOP',
    'qa:internal' => 'ENABLE_QA_INTERNAL',
    'qa:selectors' => 'ENABLE_QA_SELECTORS',
    'static-analysis' => 'ENABLE_STATIC_ANALYSIS',
    /^cache-assets\b/ => 'ENABLE_CACHE_ASSETS',
    # Jest
    /^jest#{PARALLEL}/ => 'ENABLE_JEST',
    /^jest-integration/ => 'ENABLE_JEST_INTEGRATION',
    /^jest predictive#{PARALLEL}/ => 'ENABLE_JEST_PREDICTIVE',
    # RSpec
    /^rspec/ => 'ENABLE_RSPEC',
    /^rspec(?:-all)? frontend_fixture/ => 'ENABLE_RSPEC_FRONTEND_FIXTURE',
    /^rspec unit/ => 'ENABLE_RSPEC_UNIT',
    /^rspec fast_spec_helper/ => 'ENABLE_RSPEC_FAST_SPEC_HELPER',
    /^rspec migration/ => 'ENABLE_RSPEC_MIGRATION',
    /^rspec background_migration/ => 'ENABLE_RSPEC_BACKGROUND_MIGRATION',
    /^rspec integration/ => 'ENABLE_RSPEC_INTEGRATION',
    /^rspec system/ => 'ENABLE_RSPEC_SYSTEM',
    /^rspec #{PG_JOB} praefect\b/ => 'ENABLE_RSPEC_PRAEFECT',
    /^rspec #{PG_JOB} single-db\b/ => 'ENABLE_RSPEC_SINGLE_DB',
    /^rspec #{PG_JOB} single-db-ci-connection\b/ => 'ENABLE_RSPEC_SINGLE_DB_CI_CONNECTION',
    /^rspec #{PG_JOB} single-redis\b/ => 'ENABLE_RSPEC_SINGLE_REDIS'
  }.freeze

  def initialize
    @client = Gitlab.client(
      endpoint: ENV['CI_API_V4_URL'],
      private_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE'] || '')
  end

  def variables
    @variables ||= generate_variables
  end

  def display
    variables.each do |key, value|
      puts "#{key}=#{value}"
    end
  end

  private

  attr_reader :client

  def generate_variables
    {
      START_AS_IF_FOSS: 'true',
      RUBY_VERSION: ENV['RUBY_VERSION'],
      FIND_CHANGES_MERGE_REQUEST_PROJECT_PATH: ENV['CI_MERGE_REQUEST_PROJECT_PATH'],
      FIND_CHANGES_MERGE_REQUEST_IID: ENV['CI_MERGE_REQUEST_IID'],
      **variables_from_jobs
    }
  end

  def variables_from_jobs
    variable_set = Set.new

    each_job do |job|
      variable_set.merge(variables_from(job.name))
    end

    variable_set.to_h { |v| [v.to_sym, 'true'] }
  end

  def each_job
    %i[pipeline_jobs pipeline_bridges].each do |kind|
      client.public_send(kind, ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID']).auto_paginate do |job| # rubocop:disable GitlabSecurity/PublicSend -- We're sending with static values, no concerns
        yield(job)
      end
    end
  end

  def variables_from(job_name)
    JOB_VARIABLES.select { |match, _| match === job_name }.map(&:last)
  end
end

GenerateAsIfFossEnv.new.display if $PROGRAM_NAME == __FILE__
