#!/usr/bin/env ruby
# frozen_string_literal: true

# In spec/scripts/setup/generate_as_if_foss_env_spec.rb we completely stub it
require 'gitlab' unless Object.const_defined?(:Gitlab)
require 'set'

class GenerateAsIfFossEnv
  def initialize
    @client = Gitlab.client(endpoint: ENV['CI_API_V4_URL'], private_token: '')
    @rspec_jobs = Set.new
    @jest_jobs = Set.new
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

  attr_reader :client, :rspec_jobs, :jest_jobs

  def generate_variables
    scan_jobs

    {
      START_AS_IF_FOSS: 'true',
      RUBY_VERSION: ENV['RUBY_VERSION']
    }.merge(rspec_variables).merge(jest_variables)
  end

  def scan_jobs
    each_job do |job|
      detect_rspec(job) || detect_jest(job)
    end
  end

  def each_job
    client.pipeline_jobs(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID']).auto_paginate do |job|
      yield(job)
    end
  end

  def detect_rspec(job)
    rspec_type = job.name[/^rspec ([\w\-]+)/, 1]

    rspec_jobs << rspec_type if rspec_type
  end

  def detect_jest(job)
    jest_type = job.name[/^jest([\w\-]*)/, 1]

    jest_jobs << jest_type if jest_type
  end

  def rspec_variables
    return {} if rspec_jobs.empty?

    rspec_jobs.inject({ ENABLE_RSPEC: 'true' }) do |result, rspec|
      result.merge("ENABLE_RSPEC_#{rspec.upcase.tr('-', '_')}": 'true')
    end
  end

  def jest_variables
    return {} if jest_jobs.empty?

    jest_jobs.inject({ ENABLE_JEST: 'true' }) do |result, jest|
      result.merge("ENABLE_JEST#{jest.upcase.tr('-', '_')}": 'true')
    end
  end
end

GenerateAsIfFossEnv.new.display if $PROGRAM_NAME == __FILE__
