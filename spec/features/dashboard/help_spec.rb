require 'spec_helper'

RSpec.describe 'Dashboard Help' do
  before do
    sign_in(create(:user))
  end

  it 'renders correctly markdown' do
    visit help_page_path("administration/raketasks/maintenance")

    expect(page).to have_content('Gather information about GitLab and the system it runs on')

    node = find('.documentation h2 a#user-content-check-gitlab-configuration')
    expect(node[:href]).to eq '#check-gitlab-configuration'
    expect(find(:xpath, "#{node.path}/..").text).to eq 'Check GitLab configuration'
  end
end
