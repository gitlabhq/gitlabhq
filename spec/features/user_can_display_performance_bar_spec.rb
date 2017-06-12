require 'rails_helper'

describe 'User can display performacne bar', :js do
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

      it 'does not show the performance bar by default' do
        expect(page).not_to have_css('#peek')
      end
    end
  end

  context 'when user is logged-out' do
    before do
      visit root_path
    end

    context 'when the gitlab_performance_bar feature is disabled' do
      before do
        Feature.disable('gitlab_performance_bar')
      end

      it_behaves_like 'performance bar is disabled'
    end

    context 'when the gitlab_performance_bar feature is enabled' do
      before do
        Feature.enable('gitlab_performance_bar')
      end

      it_behaves_like 'performance bar is disabled'
    end
  end

  context 'when user is logged-in' do
    before do
      login_as :user

      visit root_path
    end

    context 'when the gitlab_performance_bar feature is disabled' do
      before do
        Feature.disable('gitlab_performance_bar')
      end

      it_behaves_like 'performance bar is disabled'
    end

    context 'when the gitlab_performance_bar feature is enabled' do
      before do
        Feature.enable('gitlab_performance_bar')
      end

      it_behaves_like 'performance bar is enabled'
    end
  end
end
