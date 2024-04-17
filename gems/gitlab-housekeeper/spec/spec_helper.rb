# frozen_string_literal: true

require 'rspec/mocks'
require "gitlab/housekeeper"
require "gitlab/housekeeper/git"
require 'webmock/rspec'
require 'gitlab/rspec/all'

module HousekeeperFactory
  # rubocop: disable Metrics/ParameterLists
  def create_change(
    identifiers: %w[the identifier],
    title: 'The change title',
    description: 'The change description',
    changed_files: ['change1.txt', 'change2.txt'],
    labels: %w[some-label-1 some-label-2],
    assignees: ['thegitlabassignee'],
    reviewers: ['thegitlabreviewer'],
    mr_web_url: nil,
    non_housekeeper_changes: []
  )

    change = ::Gitlab::Housekeeper::Change.new
    change.identifiers = identifiers
    change.title = title
    change.description = description
    change.changed_files = changed_files
    change.labels = labels
    change.assignees = assignees
    change.reviewers = reviewers
    change.mr_web_url = mr_web_url
    change.non_housekeeper_changes = non_housekeeper_changes

    change
  end
  # rubocop: enable Metrics/ParameterLists
end

RSpec.configure do |config|
  config.include StubENV
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include(HousekeeperFactory)
end
