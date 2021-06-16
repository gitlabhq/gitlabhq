# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Wiki', :js do
  include DocsScreenshotHelpers
  include WikiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace, creator: user) }
  let(:wiki) { create(:project_wiki, user: user, project: project) }

  before do
    page.driver.browser.manage.window.resize_to(1366, 1024)

    sign_in(user)
    visit wiki_path(wiki)

    click_link "Create your first page"
  end

  context 'switching to content editor' do
    it 'user/project/wiki/img/use_new_editor_button' do
      screenshot_area = find('[data-testid="wiki-form-content-fieldset"]')
      scroll_to screenshot_area
      expect(screenshot_area).to have_content 'Use the new editor'
      set_crop_data(screenshot_area, 0)
    end
  end

  context 'content editor' do
    it 'user/project/wiki/img/content_editor' do
      content_editor_testid = '[data-testid="wiki-form-content-fieldset"]'

      click_button 'Use the new editor'

      expect(page).to have_css(content_editor_testid)

      screenshot_area = find(content_editor_testid)
      scroll_to screenshot_area

      find("#{content_editor_testid} [contenteditable]").send_keys '## Using the Content Editor'

      set_crop_data(screenshot_area, 0)
    end
  end
end
