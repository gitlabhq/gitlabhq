# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'unsupported work item types use legacy issue views', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:incident)  { create(:work_item, :incident, project: project) }
  let_it_be(:service_desk_issue) do
    create(:issue, author: Users::Internal.support_bot, external_author: 'user@example.com', project: project)
  end

  let_it_be(:user) { create(:user) }

  let(:use_work_items_view) { false }
  let!(:user_preference) { create(:user_preference, use_work_items_view: use_work_items_view) }

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
      # Ensure the work item feedback badge is not rendered for unsupported types
      expect(page).not_to have_selector('[data-testid="work-item-feedback"]')
      expect(page).not_to have_content(/New issue look:/)
    end
  end

  context 'when work item is incident' do
    let(:work_item) { incident }

    it_behaves_like 'a work item that renders using the legacy issue view'
    context 'when use_work_items_view user setting is true' do
      let(:use_work_items_view) { true }

      it_behaves_like 'a work item that renders using the legacy issue view'
    end
  end

  context 'when work item is Service Desk issue' do
    let(:work_item) { service_desk_issue }

    it_behaves_like 'a work item that renders using the legacy issue view'
    context 'when use_work_items_view user setting is true' do
      let(:use_work_items_view) { true }

      it_behaves_like 'a work item that renders using the legacy issue view'
    end
  end
end
