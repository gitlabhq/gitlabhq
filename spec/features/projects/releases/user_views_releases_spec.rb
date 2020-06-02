# frozen_string_literal: true

require 'spec_helper'

describe 'User views releases', :js do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:release) { create(:release, project: project, name: 'The first release' ) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:guest) { create(:user) }

  before do
    project.add_maintainer(maintainer)
    project.add_guest(guest)
  end

  context('when the user is a maintainer') do
    before do
      gitlab_sign_in(maintainer)
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
      let(:direct_asset_link) { Gitlab::Routing.url_helpers.project_release_url(project, release) << release_link.filepath }

      it 'sees the link' do
        visit project_releases_path(project)

        page.within('.js-assets-list') do
          expect(page).to have_link release_link.name, href: direct_asset_link
          expect(page).not_to have_content('(external source)')
        end
      end

      context 'when there is a link redirect' do
        let!(:release_link) { create(:release_link, release: release, name: 'linux-amd64 binaries', filepath: '/binaries/linux-amd64', url: url) }
        let(:url) { "#{project.web_url}/-/jobs/1/artifacts/download" }

        it 'sees the link' do
          visit project_releases_path(project)

          page.within('.js-assets-list') do
            expect(page).to have_link release_link.name, href: direct_asset_link
            expect(page).not_to have_content('(external source)')
          end
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
        release = create :release, project: project, tag: 'debian/2.4.0-1'
        visit project_releases_path(project)

        expect(page).to have_content(release.name)
        expect(page).to have_content(release.tag)
      end
    end
  end

  context('when the user is a guest') do
    before do
      gitlab_sign_in(guest)
    end

    it 'renders release info except for Git-related data' do
      visit project_releases_path(project)

      within('.release-block') do
        expect(page).to have_content(release.description)

        # The following properties (sometimes) include Git info,
        # so they are not rendered for Guest users
        expect(page).not_to have_content(release.name)
        expect(page).not_to have_content(release.tag)
        expect(page).not_to have_content(release.commit.short_id)
      end
    end
  end
end
