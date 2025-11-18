# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'time'
require 'gitlab'

unless ENV['CI']
  puts 'Necessary environment variable CI not defined.'
  exit(-1)
end

ENDPOINT = ENV.fetch('CI_API_V4_URL')
PROJECT_PATH = ENV.fetch('CI_PROJECT_PATH')

TOKEN = ENV.fetch('DATABASE_PROJECT_TOKEN')
DB_PIPELINE_NOTE_TAG = 'gitlab-org/database-team/gitlab-com-database-testing:identifiable-note'
INVALIDATED_RESULTS_MSG_TAG = 'gitlab-org/database-team/gitlab-com-database-testing:identifiable-note-invalidated'

INVALIDATED_RESULTS_MSG = <<~MSG.freeze
  ## ⚠️

  Please note that the database testing pipeline results in this comment
  are no longer valid due to a commit being added to the merge request that has
  changed one or more files.

  Please run another database testing pipeline for the most accurate results.

  <!-- #{INVALIDATED_RESULTS_MSG_TAG} -->
  ***

MSG

merge_request_id = ARGV[0]
most_recent_commit_timestamp = Time.at(ARGV[1].to_i)

client = Gitlab.client(endpoint: ENDPOINT, private_token: TOKEN)

puts "Fetching discussions on merge request #{merge_request_id}"
client.merge_request_notes(PROJECT_PATH, merge_request_id).auto_paginate.each do |discussion|
  next unless discussion.body.include?(DB_PIPELINE_NOTE_TAG)
  next if discussion.body.include? INVALIDATED_RESULTS_MSG_TAG

  puts "Found discussion #{discussion.id} which was created at #{discussion.created_at}"
  puts "Last committed timestamp is #{most_recent_commit_timestamp}"
  next unless Time.iso8601(discussion.created_at) < most_recent_commit_timestamp

  puts "Annotating body of #{discussion.id}"
  annotated_body = "#{INVALIDATED_RESULTS_MSG}#{discussion.body}"

  client.edit_merge_request_note(PROJECT_PATH, merge_request_id, discussion.id, annotated_body)
end
