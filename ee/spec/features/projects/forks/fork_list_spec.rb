require 'spec_helper'

describe 'listing forks of a project' do
  include ProjectForksHelper
  include ExternalAuthorizationServiceHelpers

  let(:source) { create(:project, :public, :repository) }
  let!(:fork) { fork_project(source, nil, repository: true) }
  let(:user) { create(:user) }

  before do
    source.add_master(user)
    sign_in(user)
  end

  it 'shows the forked project in the list with commit as description' do
    visit project_forks_path(source)

    page.within('li.project-row') do
      expect(page).to have_content(fork.full_name)
      expect(page).to have_css('a.commit-row-message')
    end
  end

  it 'does not show the commit message when an external authorization service is used' do
    enable_external_authorization_service_check

    visit project_forks_path(source)

    page.within('li.project-row') do
      expect(page).to have_content(fork.full_name)
      expect(page).not_to have_css('a.commit-row-message')
    end
  end
end
