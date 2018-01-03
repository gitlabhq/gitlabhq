require 'spec_helper'

describe 'Dashboard > label filter', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }
  let(:project2) { create(:project, name: 'test2', path: 'test2', namespace: user.namespace) }
  let(:label) { create(:label, title: 'bug', color: '#ff0000') }
  let(:label2) { create(:label, title: 'bug') }

  before do
    project.labels << label
    project2.labels << label2

    sign_in(user)
    visit issues_dashboard_path
  end

  context 'duplicate labels' do
    it 'removes duplicate labels' do
      page.within('.labels-filter') do
        click_button 'Label'
      end

      page.within('.dropdown-menu-labels') do
        expect(page).to have_selector('.dropdown-content a', text: 'bug', count: 1)
      end
    end
  end
end
