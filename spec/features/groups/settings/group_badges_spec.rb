require 'spec_helper'

feature 'Group Badges' do
  include WaitForRequests

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:badge_link_url) { 'https://gitlab.com/gitlab-org/gitlab-ee/commits/master'}
  let(:badge_image_url) { 'https://gitlab.com/gitlab-org/gitlab-ee/badges/master/build.svg'}
  let!(:badge_1) { create(:group_badge, group: group) }
  let!(:badge_2) { create(:group_badge, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)

    visit(group_settings_badges_path(group))
  end

  it 'shows a list of badges', :js do
    page.within '.badge-settings' do
      wait_for_requests

      rows = all('.card-body > div')
      expect(rows.length).to eq 2
      expect(rows[0]).to have_content badge_1.link_url
      expect(rows[1]).to have_content badge_2.link_url
    end
  end

  context 'adding a badge', :js do
    it 'user can preview a badge' do
      page.within '.badge-settings form' do
        fill_in 'badge-link-url', with: badge_link_url
        fill_in 'badge-image-url', with: badge_image_url
        within '#badge-preview' do
          expect(find('a')[:href]).to eq badge_link_url
          expect(find('a img')[:src]).to eq badge_image_url
        end
      end
    end

    it do
      page.within '.badge-settings' do
        fill_in 'badge-link-url', with: badge_link_url
        fill_in 'badge-image-url', with: badge_image_url

        click_button 'Add badge'
        wait_for_requests

        within '.card-body' do
          expect(find('a')[:href]).to eq badge_link_url
          expect(find('a img')[:src]).to eq badge_image_url
        end
      end
    end
  end

  context 'editing a badge', :js do
    it 'form is shown when clicking edit button in list' do
      page.within '.badge-settings' do
        wait_for_requests
        rows = all('.card-body > div')
        expect(rows.length).to eq 2
        rows[1].find('[aria-label="Edit"]').click

        within 'form' do
          expect(find('#badge-link-url').value).to eq badge_2.link_url
          expect(find('#badge-image-url').value).to eq badge_2.image_url
        end
      end
    end

    it 'updates a badge when submitting the edit form' do
      page.within '.badge-settings' do
        wait_for_requests
        rows = all('.card-body > div')
        expect(rows.length).to eq 2
        rows[1].find('[aria-label="Edit"]').click
        within 'form' do
          fill_in 'badge-link-url', with: badge_link_url
          fill_in 'badge-image-url', with: badge_image_url

          click_button 'Save changes'
          wait_for_requests
        end

        rows = all('.card-body > div')
        expect(rows.length).to eq 2
        expect(rows[1]).to have_content badge_link_url
      end
    end
  end

  context 'deleting a badge', :js do
    def click_delete_button(badge_row)
      badge_row.find('[aria-label="Delete"]').click
    end

    it 'shows a modal when deleting a badge' do
      wait_for_requests
      rows = all('.card-body > div')
      expect(rows.length).to eq 2

      click_delete_button(rows[1])

      expect(find('.modal .modal-title')).to have_content 'Delete badge?'
    end

    it 'deletes a badge when confirming the modal' do
      wait_for_requests
      rows = all('.card-body > div')
      expect(rows.length).to eq 2
      click_delete_button(rows[1])

      find('.modal .btn-danger').click
      wait_for_requests

      rows = all('.card-body > div')
      expect(rows.length).to eq 1
      expect(rows[0]).to have_content badge_1.link_url
    end
  end
end
