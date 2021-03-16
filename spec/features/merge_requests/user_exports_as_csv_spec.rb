# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > Exports as CSV', :js do
  let!(:project) { create(:project, :public, :repository) }
  let!(:user)    { project.creator }
  let!(:open_mr) { create(:merge_request, title: 'Bugfix1', source_project: project, target_project: project, source_branch: 'bugfix1') }

  before do
    sign_in(user)
    visit(project_merge_requests_path(project))
  end

  subject { page.find('.nav-controls') }

  it { is_expected.to have_selector '[data-testid="export-csv-button"]' }

  context 'button is clicked' do
    before do
      page.within('.nav-controls') do
        find('[data-testid="export-csv-button"]').click
      end
    end

    it 'shows a success message' do
      click_link('Export merge requests')

      expect(page).to have_content 'Your CSV export has started.'
      expect(page).to have_content "It will be emailed to #{user.email} when complete"
    end
  end
end
