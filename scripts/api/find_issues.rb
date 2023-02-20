# frozen_string_literal: true

require_relative 'base'

class FindIssues < Base
  def execute(search_data)
    client.issues(project, search_data)
  end
end
