# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views Release', :js do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  let(:release) do
    create(:release,
           project: project,
           name: 'The first release',
           description: '**Lorem** _ipsum_ dolor sit [amet](https://example.com)')
  end

  before do
    project.add_developer(user)

    sign_in(user)

    visit project_release_path(project, release)
  end

  it_behaves_like 'page meta description', 'Lorem ipsum dolor sit amet'

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
      expect(page).to have_content('Lorem ipsum dolor sit amet')
    end
  end
end
