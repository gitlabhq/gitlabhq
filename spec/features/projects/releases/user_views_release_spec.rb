# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views Release', :js do
  let(:project) { create(:project, :repository) }
  let(:release) { create(:release, project: project, name: 'The first release' ) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)

    gitlab_sign_in(user)

    visit project_release_path(project, release)
  end

  it 'renders the breadcrumbs' do
    within('.breadcrumbs') do
      expect(page).to have_content("#{project.creator.name} #{project.name} Releases #{release.name}")

      expect(page).to have_link(project.creator.name, href: user_path(project.creator))
      expect(page).to have_link(project.name, href: project_path(project))
      expect(page).to have_link('Releases', href: project_releases_path(project))
      expect(page).to have_link(release.name, href: project_release_path(project, release))
    end
  end

  it 'renders the release details' do
    within('.release-block') do
      expect(page).to have_content(release.name)
      expect(page).to have_content(release.tag)
      expect(page).to have_content(release.commit.short_id)
      expect(page).to have_content(release.description)
    end
  end
end
