# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > Exports as CSV', :js do
  let!(:project) { create(:project, :public, :repository) }
  let!(:user)    { project.creator }
  let!(:open_mr) { create(:merge_request, title: 'Bugfix1', source_project: project, target_project: project, source_branch: 'bugfix1') }

  before do
    sign_in(user)
  end

  subject { page.find('.nav-controls') }

  context 'feature is not enabled' do
    before do
      stub_feature_flags(export_merge_requests_as_csv: false)
      visit(project_merge_requests_path(project))
    end

    it { is_expected.not_to have_button('Export as CSV') }
  end

  context 'feature is enabled for a project' do
    before do
      stub_feature_flags(export_merge_requests_as_csv: project)
      visit(project_merge_requests_path(project))
    end

    it { is_expected.to have_button('Export as CSV') }

    context 'button is clicked' do
      before do
        click_button('Export as CSV')
      end

      it 'shows a success message' do
        click_link('Export merge requests')

        expect(page).to have_content 'Your CSV export has started.'
        expect(page).to have_content "It will be emailed to #{user.email} when complete"
      end
    end
  end
end
