require 'spec_helper'

feature 'Toggle Whitespace Changes', js: true, feature: true do
  before do
    login_as :admin
    # something = create(:something)
    # project = something.something_project
    # visit diffs_namespace_project_something_path(project.namespace, project, something)
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
