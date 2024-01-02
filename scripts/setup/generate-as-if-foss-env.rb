#!/usr/bin/env ruby
# frozen_string_literal: true

require 'gitlab'
require 'set'

client = Gitlab.client(endpoint: ENV['CI_API_V4_URL'], private_token: '')

rspec_jobs = Set.new

client.pipeline_jobs(ENV['CI_PROJECT_ID'], ENV['CI_PIPELINE_ID']).auto_paginate do |job|
  rspec_type = job.name[/^rspec ([\w\-]+)/, 1]

  rspec_jobs << rspec_type if rspec_type
end

puts 'START_AS_IF_FOSS=true', "RUBY_VERSION=#{ENV['RUBY_VERSION']}"
puts 'ENABLE_RSPEC=true' if rspec_jobs.any?

rspec_jobs.each do |rspec|
  puts "ENABLE_RSPEC_#{rspec.upcase.tr('-', '_')}=true"
end
