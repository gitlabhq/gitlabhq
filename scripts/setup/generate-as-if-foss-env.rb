#!/usr/bin/env ruby
# frozen_string_literal: true

# In spec/scripts/setup/generate_as_if_foss_env_spec.rb we completely stub it
require 'gitlab' unless Object.const_defined?(:Gitlab)
require 'set' # rubocop:disable Lint/RedundantRequireStatement -- Ruby 3.1 and earlier needs this. Drop this line after Ruby 3.2+ is only supported.

class GenerateAsIfFossEnv
  FOSS_JOBS = Set.new(%w[
    build-assets-image
    build-qa-image
    compile-production-assets
    compile-storybook
    compile-test-assets
    eslint
    generate-apollo-graphql-schema
    graphql-schema-dump
    jest
    jest-integration
    qa:internal
    qa:selectors
    static-analysis
  ]).freeze

  def initialize
    @client = Gitlab.client(endpoint: ENV['CI_API_V4_URL'], private_token: '')
    @rspec_jobs = Set.new
    @other_jobs = Set.new
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

  attr_reader :client, :rspec_jobs, :other_jobs

  def generate_variables
    scan_jobs

    {
      START_AS_IF_FOSS: 'true',
      RUBY_VERSION: ENV['RUBY_VERSION']
    }.merge(rspec_variables).merge(other_jobs_variables)
  end

  def scan_jobs
    each_job do |job|
      detect_rspec(job) || detect_other_jobs(job)
    end
  end

  def each_job
    client.pipeline_jobs(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID']).auto_paginate do |job|
      yield(job)
    end
  end

  def detect_rspec(job)
    rspec_type = job.name[/^rspec(?:-all)? ([\w\-]+)/, 1]

    rspec_jobs << rspec_type if rspec_type
  end

  def detect_other_jobs(job)
    other_jobs << job.name if FOSS_JOBS.member?(job.name)
  end

  def rspec_variables
    return {} if rspec_jobs.empty?

    rspec_jobs.inject({ ENABLE_RSPEC: 'true' }) do |result, rspec|
      result.merge("ENABLE_RSPEC_#{job_name_to_variable_name(rspec)}": 'true')
    end
  end

  def other_jobs_variables
    other_jobs.inject({}) do |result, job_name|
      result.merge("ENABLE_#{job_name_to_variable_name(job_name)}": 'true')
    end
  end

  def job_name_to_variable_name(name)
    name.upcase.tr('-: ', '_')
  end
end

GenerateAsIfFossEnv.new.display if $PROGRAM_NAME == __FILE__
