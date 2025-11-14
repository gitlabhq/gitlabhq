# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Confidential notes on issues", :js, feature_category: :team_planning do
  it_behaves_like 'confidential notes on issuables' do
    let_it_be(:issuable_parent) { create(:project) }
    let_it_be(:issuable) { create(:issue, project: issuable_parent) }
    let_it_be(:user) { create(:user) }

    let(:issuable_path) { project_issue_path(issuable_parent, issuable) }
  end
end
