# frozen_string_literal: true

require_relative 'base'

class CommitMergeRequests < Base
  def initialize(options)
    super
    @sha = options.fetch(:sha)
  end

  def execute
    client.commit_merge_requests(project, sha)
  end

  private

  attr_reader :sha
end
