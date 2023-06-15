# frozen_string_literal: true

require_relative 'base'

class CreateMergeRequestNote < Base
  def initialize(options)
    super
    @merge_request = options.fetch(:merge_request)
  end

  def execute(content)
    client.create_merge_request_comment(
      project,
      merge_request.iid,
      content
    )
  end

  private

  attr_reader :merge_request
end
