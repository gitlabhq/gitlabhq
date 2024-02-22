# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesFinder, feature_category: :team_planning do
  include_context 'Issues or WorkItems Finder context', :issue

  it_behaves_like 'issues or work items finder', :issue, '{Issues|WorkItems}Finder#execute context'
end
