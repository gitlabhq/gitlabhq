# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesFinder, feature_category: :team_planning do
  include_context 'IssuesFinder context'

  it_behaves_like 'issues or work items finder', :issue, 'IssuesFinder#execute context'
end
