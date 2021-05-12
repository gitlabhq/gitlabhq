# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views releases', :js do
  let_it_be(:today) { Time.zone.now }
  let_it_be(:yesterday) { today - 1.day }
  let_it_be(:tomorrow) { today + 1.day }

  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:release_v1) { create(:release, project: project, tag: 'v1', name: 'The first release', released_at: yesterday, created_at: today) }
  let_it_be(:release_v2) { create(:release, project: project, tag: 'v2-with-a/slash', name: 'The second release', released_at: today, created_at: yesterday) }
  let_it_be(:release_v3) { create(:release, project: project, tag: 'v3', name: 'The third release', released_at: tomorrow, created_at: tomorrow) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:guest) { create(:user) }

  before do
    project.add_maintainer(maintainer)
    project.add_guest(guest)
  end

  context('when the user is a maintainer') do
    before do
      sign_in(maintainer)

      visit project_releases_path(project)
    end

    it 'sees the release' do
      page.within("##{release_v1.tag}") do
        expect(page).to have_content(release_v1.name)
        expect(page).to have_content(release_v1.tag)
        expect(page).not_to have_content('Upcoming Release')
      end
    end

    context 'when there is a link as an asset' do
      let!(:release_link) { create(:release_link, release: release_v1, url: url ) }
      let(:url) { "#{project.web_url}/-/jobs/1/artifacts/download" }
      let(:direct_asset_link) { Gitlab::Routing.url_helpers.project_release_url(project, release_v1) << "/downloads#{release_link.filepath}" }

      it 'sees the link' do
        page.within("##{release_v1.tag} .js-assets-list") do
          expect(page).to have_link release_link.name, href: direct_asset_link
          expect(page).not_to have_css('[data-testid="external-link-indicator"]')
        end
      end

      context 'when there is a link redirect' do
        let!(:release_link) { create(:release_link, release: release_v1, name: 'linux-amd64 binaries', filepath: '/binaries/linux-amd64', url: url) }
        let(:url) { "#{project.web_url}/-/jobs/1/artifacts/download" }

        it 'sees the link', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/329301' do
          page.within("##{release_v1.tag} .js-assets-list") do
            expect(page).to have_link release_link.name, href: direct_asset_link
            expect(page).not_to have_css('[data-testid="external-link-indicator"]')
          end
        end
      end

      context 'when url points to external resource' do
        let(:url) { 'http://google.com/download' }

        it 'sees that the link is external resource', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/329302' do
          page.within("##{release_v1.tag} .js-assets-list") do
            expect(page).to have_css('[data-testid="external-link-indicator"]')
          end
        end
      end
    end

    context 'with an upcoming release' do
      it 'sees the upcoming tag' do
        page.within("##{release_v3.tag}") do
          expect(page).to have_content('Upcoming Release')
        end
      end
    end

    context 'with a tag containing a slash' do
      it 'sees the release' do
        page.within("##{release_v2.tag.parameterize}") do
          expect(page).to have_content(release_v2.name)
          expect(page).to have_content(release_v2.tag)
        end
      end
    end

    context 'sorting' do
      def sort_page(by:, direction:)
        within '[data-testid="releases-sort"]' do
          find('.dropdown-toggle').click

          click_button(by, class: 'dropdown-item')

          find('.sorting-direction-button').click if direction == :ascending
        end
      end

      shared_examples 'releases sort order' do
        it "sorts the releases #{description}" do
          card_titles = page.all('.release-block .card-title', minimum: expected_releases.count)

          card_titles.each_with_index do |title, index|
            expect(title).to have_content(expected_releases[index].name)
          end
        end
      end

      context "when the page is sorted by the default sort order" do
        let(:expected_releases) { [release_v3, release_v2, release_v1] }

        it_behaves_like 'releases sort order'
      end

      context "when the page is sorted by created_at ascending " do
        let(:expected_releases) { [release_v2, release_v1, release_v3] }

        before do
          sort_page by: 'Created date', direction: :ascending
        end

        it_behaves_like 'releases sort order'
      end
    end
  end

  context('when the user is a guest') do
    before do
      sign_in(guest)
    end

    it 'renders release info except for Git-related data' do
      visit project_releases_path(project)

      within('.release-block', match: :first) do
        expect(page).to have_content(release_v3.description)

        # The following properties (sometimes) include Git info,
        # so they are not rendered for Guest users
        expect(page).not_to have_content(release_v3.name)
        expect(page).not_to have_content(release_v3.tag)
        expect(page).not_to have_content(release_v3.commit.short_id)
      end
    end
  end
end
