require 'spec_helper'

feature 'Update Epic', :js do
  include DropzoneHelper

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }

  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [ ] Incomplete entry 1
    MARKDOWN
  end

  let(:epic) { create(:epic, group: group, description: markdown) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when user who is not a group member displays the epic' do
    it 'does not show the Edit button' do
      visit group_epic_path(group, epic)

      expect(page).not_to have_selector('.btn-edit')
    end
  end

  context 'when user with developer access displays the epic' do
    before do
      group.add_developer(user)
      visit group_epic_path(group, epic)
      wait_for_requests
    end

    context 'update form' do
      before do
        find('.btn-edit').click
      end

      it 'updates the epic' do
        fill_in 'issuable-title', with: 'New epic title'
        fill_in 'issue-description', with: 'New epic description'

        page.within('.detail-page-description') { click_link('Preview') }
        expect(find('.md-preview')).to have_content('New epic description')

        click_button 'Save changes'

        expect(find('.issuable-details h2.title')).to have_content('New epic title')
        expect(find('.issuable-details .description')).to have_content('New epic description')
      end

      it 'edits full screen' do
        page.within('.detail-page-description') { find('.js-zen-enter').click }

        expect(page).to have_selector('.div-dropzone-wrapper.fullscreen')
      end

      it 'uploads a file when dragging into textarea' do
        link_css = 'a.no-attachment-icon img[alt="banana_sample"]'
        link_match = %r{/groups/#{Regexp.escape(group.full_path)}/-/uploads/\h{32}/banana_sample\.gif\z}
        dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

        expect(page.find_field("issue-description").value).to have_content('banana_sample')

        page.within('.detail-page-description') { click_link('Preview') }
        wait_for_requests

        within('.md-preview') do
          link = find(link_css)['src']
          expect(link).to match(link_match)
        end

        click_button 'Save changes'
        wait_for_requests

        link = find(link_css)['src']
        expect(link).to match(link_match)
      end

      # Autocomplete is disabled for epics until #4084 is resolved
      describe 'autocomplete disabled' do
        it 'does not open atwho container' do
          find('#issue-description').native.send_keys('@')
          expect(page).not_to have_selector('.atwho-container')
        end
      end
    end

    it 'updates the tasklist' do
      expect(page).to have_selector('ul.task-list',      count: 1)
      expect(page).to have_selector('li.task-list-item', count: 1)
      expect(page).to have_selector('ul input[checked]', count: 0)

      find('.task-list .task-list-item', text: 'Incomplete entry 1').find('input').click

      expect(page).to have_selector('ul input[checked]', count: 1)
    end
  end

  context 'when user with owner access displays the epic' do
    before do
      group.add_owner(user)
      visit group_epic_path(group, epic)
      wait_for_requests
    end

    it 'does not show delete button inside the edit form' do
      find('.btn-edit').click

      expect(page).not_to have_selector('.issuable-details .btn-danger')
    end
  end
end
