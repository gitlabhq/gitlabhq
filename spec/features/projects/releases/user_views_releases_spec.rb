# frozen_string_literal: true

require 'spec_helper'

describe 'User views releases', :js do
  let!(:project) { create(:project, :repository) }
  let!(:release) { create(:release, project: project ) }
  let!(:user) { create(:user) }

  before do
    project.add_maintainer(user)

    gitlab_sign_in(user)
  end

  it 'sees the release' do
    visit project_releases_path(project)

    expect(page).to have_content(release.name)
    expect(page).to have_content(release.tag)
    expect(page).not_to have_content('Upcoming Release')
  end

  context 'when there is a link as an asset' do
    let!(:release_link) { create(:release_link, release: release, url: url ) }
    let(:url) { "#{project.web_url}/-/jobs/1/artifacts/download" }

    it 'sees the link' do
      visit project_releases_path(project)

      page.within('.js-assets-list') do
        expect(page).to have_link release_link.name, href: release_link.url
        expect(page).not_to have_content('(external source)')
      end
    end

    context 'when url points to external resource' do
      let(:url) { 'http://google.com/download' }

      it 'sees that the link is external resource' do
        visit project_releases_path(project)

        page.within('.js-assets-list') do
          expect(page).to have_content('(external source)')
        end
      end
    end
  end

  context 'with an upcoming release' do
    let(:tomorrow) { Time.zone.now + 1.day }
    let!(:release) { create(:release, project: project, released_at: tomorrow ) }

    it 'sees the upcoming tag' do
      visit project_releases_path(project)

      expect(page).to have_content('Upcoming Release')
    end
  end

  context 'with a tag containing a slash' do
    it 'sees the release' do
      release = create :release, :with_evidence, project: project, tag: 'debian/2.4.0-1'
      visit project_releases_path(project)

      expect(page).to have_content(release.name)
      expect(page).to have_content(release.tag)
    end
  end
end
