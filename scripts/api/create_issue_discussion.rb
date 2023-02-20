# frozen_string_literal: true

require_relative 'base'

class CreateIssueDiscussion < Base
  def execute(discussion_data)
    client.post(
      "/projects/#{client.url_encode project}/issues/#{discussion_data.delete(:issue_iid)}/discussions",
      body: discussion_data
    )
  end
end
