require 'spec_helper'

describe 'New Epic', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'empty epic list' do
    context 'when user who is not a group member views the epic list' do
      it 'does not show the create button' do
        visit group_epics_path(group)

        expect(page).not_to have_selector('.new-epic-dropdown  .btn-success')
      end
    end

    context 'when user with owner views the epic list' do
      before do
        group.add_owner(user)
        visit group_epics_path(group)
      end

      it 'does show the create button' do
        expect(page).to have_selector('.new-epic-dropdown .btn-success')
      end
    end
  end

  context 'has epics in list' do
    let!(:epics) { create_list(:epic, 2, group: group) }

    context 'when user who is not a group member views the epic list' do
      before do
        visit group_epics_path(group)
      end

      it 'does not show the create button' do
        expect(page).not_to have_selector('.new-epic-dropdown .btn-success')
      end
    end

    context 'when user with owner views the epic list' do
      before do
        group.add_owner(user)
        visit group_epics_path(group)
      end

      it 'does show the create button' do
        expect(page).to have_selector('.new-epic-dropdown .btn-success')
      end

      it 'can create epic' do
        find('.new-epic-dropdown .btn-success').click
        find('.new-epic-dropdown .dropdown-menu input').set('test epic title')
        find('.new-epic-dropdown .dropdown-menu .btn-success').click

        wait_for_requests

        expect(find('.issuable-details h2.title')).to have_content('test epic title')
      end
    end
  end
end
