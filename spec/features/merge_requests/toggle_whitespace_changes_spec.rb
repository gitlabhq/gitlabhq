require 'spec_helper'

feature 'Toggle Whitespace Changes', js: true, feature: true do
  before do
    sign_in(create(:admin))
    merge_request = create(:merge_request)
    project = merge_request.source_project
    visit diffs_project_merge_request_path(project, merge_request)
  end

  it 'has a button to toggle whitespace changes' do
    expect(page).to have_content 'Hide whitespace changes'
  end

  describe 'clicking "Hide whitespace changes" button' do
    it 'toggles the "Hide whitespace changes" button' do
      click_link 'Hide whitespace changes'

      expect(page).to have_content 'Show whitespace changes'
    end
  end
end
