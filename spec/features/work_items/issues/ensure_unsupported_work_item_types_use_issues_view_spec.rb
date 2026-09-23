# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'unsupported work item types use legacy issue views', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:incident)  { create(:work_item, :incident, project: project) }
  let_it_be(:support_bot) { create(:support_bot) }
  let_it_be(:ticket) do
    create(:issue, :ticket, author: support_bot, external_author: 'user@example.com', project: project)
  end

  let_it_be(:user) { create(:user) }

  before_all do
    project.add_developer(user)
  end

  shared_examples 'a work item that renders using the legacy issue view' do
    before do
      sign_in(user)
    end

    it 'verifies presence of legacy issue elements and absence of work item elements' do
      visit project_issue_path(project, work_item)

      # Work item app didn't render
      expect(page).not_to have_selector('.work-item-view')
      # Legacy issue app rendered
      expect(page).to have_selector('.issuable-details')
    end
  end

  context 'when work item is incident' do
    let(:work_item) { incident }

    it_behaves_like 'a work item that renders using the legacy issue view'
  end

  context 'when work item is a Service Desk ticket' do
    let(:work_item) { ticket }

    it_behaves_like 'a work item that renders using the legacy issue view'
  end
end
