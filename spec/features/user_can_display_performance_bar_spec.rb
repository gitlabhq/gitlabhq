require 'rails_helper'

describe 'User can display performance bar', :js do
  shared_examples 'performance bar is disabled' do
    it 'does not show the performance bar by default' do
      expect(page).not_to have_css('#peek')
    end

    context 'when user press `pb`' do
      before do
        find('body').native.send_keys('pb')
      end

      it 'does not show the performance bar by default' do
        expect(page).not_to have_css('#peek')
      end
    end
  end

  shared_examples 'performance bar is enabled' do
    it 'does not show the performance bar by default' do
      expect(page).not_to have_css('#peek')
    end

    context 'when user press `pb`' do
      before do
        find('body').native.send_keys('pb')
      end

      it 'shows the performance bar' do
        expect(page).to have_css('#peek')
      end
    end
  end

  let(:group) { create(:group) }

  context 'when user is logged-out' do
    before do
      visit root_path
    end

    context 'when the performance_bar feature is disabled' do
      before do
        stub_application_setting(performance_bar_allowed_group_id: nil)
      end

      it_behaves_like 'performance bar is disabled'
    end

    context 'when the performance_bar feature is enabled' do
      before do
        stub_application_setting(performance_bar_allowed_group_id: group.id)
      end

      it_behaves_like 'performance bar is disabled'
    end
  end

  context 'when user is logged-in' do
    before do
      user = create(:user)

      sign_in(user)
      group.add_guest(user)

      visit root_path
    end

    context 'when the performance_bar feature is disabled' do
      before do
        stub_application_setting(performance_bar_allowed_group_id: nil)
      end

      it_behaves_like 'performance bar is disabled'
    end

    context 'when the performance_bar feature is enabled' do
      before do
        stub_application_setting(performance_bar_allowed_group_id: group.id)
      end

      it_behaves_like 'performance bar is enabled'
    end
  end
end
