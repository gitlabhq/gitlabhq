require 'spec_helper'

RSpec.describe 'admin active tab' do
  before do
    sign_in(create(:admin))
  end

  shared_examples 'page has active tab' do |title|
    it "activates #{title} tab" do
      expect(page).to have_selector('.layout-nav .nav-links > li.active', count: 1)
      expect(page.find('.layout-nav li.active')).to have_content(title)
    end
  end

  shared_examples 'page has active sub tab' do |title|
    it "activates #{title} sub tab" do
      expect(page).to have_selector('.sub-nav li.active', count: 1)
      expect(page.find('.sub-nav li.active')).to have_content(title)
    end
  end

  context 'on home page' do
    before do
      visit admin_root_path
    end

    it_behaves_like 'page has active tab', 'Overview'
  end

  context 'on projects' do
    before do
      visit admin_projects_path
    end

    it_behaves_like 'page has active tab', 'Overview'
    it_behaves_like 'page has active sub tab', 'Projects'
  end

  context 'on groups' do
    before do
      visit admin_groups_path
    end

    it_behaves_like 'page has active tab', 'Overview'
    it_behaves_like 'page has active sub tab', 'Groups'
  end

  context 'on users' do
    before do
      visit admin_users_path
    end

    it_behaves_like 'page has active tab', 'Overview'
    it_behaves_like 'page has active sub tab', 'Users'
  end

  context 'on logs' do
    before do
      visit admin_logs_path
    end

    it_behaves_like 'page has active tab', 'Monitoring'
    it_behaves_like 'page has active sub tab', 'Logs'
  end

  context 'on messages' do
    before do
      visit admin_broadcast_messages_path
    end

    it_behaves_like 'page has active tab', 'Messages'
  end

  context 'on hooks' do
    before do
      visit admin_hooks_path
    end

    it_behaves_like 'page has active tab', 'Hooks'
  end

  context 'on background jobs' do
    before do
      visit admin_background_jobs_path
    end

    it_behaves_like 'page has active tab', 'Monitoring'
    it_behaves_like 'page has active sub tab', 'Background Jobs'
  end
end
