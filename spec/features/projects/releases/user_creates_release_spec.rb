# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates release', :js do
  include Spec::Support::Helpers::Features::ReleasesHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:milestone_1) { create(:milestone, project: project, title: '1.1') }
  let_it_be(:milestone_2) { create(:milestone, project: project, title: '1.2') }
  let_it_be(:user) { create(:user) }

  let(:new_page_url) { new_project_release_path(project) }

  before do
    project.add_developer(user)

    sign_in(user)

    visit new_page_url

    wait_for_requests
  end

  it 'renders the breadcrumbs', :aggregate_failures do
    within('.breadcrumbs') do
      expect(page).to have_content("#{project.creator.name} #{project.name} New Release")

      expect(page).to have_link(project.creator.name, href: user_path(project.creator))
      expect(page).to have_link(project.name, href: project_path(project))
      expect(page).to have_link('New Release', href: new_project_release_path(project))
    end
  end

  it 'defaults the "Create from" dropdown to the project\'s default branch' do
    expect(page.find('[data-testid="create-from-field"] .ref-selector button')).to have_content(project.default_branch)
  end

  context 'when the "Save release" button is clicked' do
    let(:tag_name) { 'v2.0.31' }
    let(:release_title) { 'A most magnificent release' }
    let(:release_notes) { 'Best. Release. **Ever.** :rocket:' }
    let(:link_1) { { url: 'https://gitlab.example.com/runbook', title: 'An example runbook', type: 'runbook' } }
    let(:link_2) { { url: 'https://gitlab.example.com/other', title: 'An example link', type: 'other' } }

    before do
      fill_out_form_and_submit
    end

    it 'creates a new release when "Create release" is clicked and redirects to the release\'s dedicated page', :aggregate_failures do
      release = project.releases.last

      expect(release.tag).to eq(tag_name)
      expect(release.sha).to eq(commit.id)
      expect(release.name).to eq(release_title)
      expect(release.milestones.first.title).to eq(milestone_1.title)
      expect(release.milestones.second.title).to eq(milestone_2.title)
      expect(release.description).to eq(release_notes)
      expect(release.links.length).to eq(2)

      link = release.links.find { |l| l.link_type == link_1[:type] }
      expect(link.url).to eq(link_1[:url])
      expect(link.name).to eq(link_1[:title])

      link = release.links.find { |l| l.link_type == link_2[:type] }
      expect(link.url).to eq(link_2[:url])
      expect(link.name).to eq(link_2[:title])

      expect(page).to have_current_path(project_release_path(project, release))
    end
  end

  context 'when the "Cancel" button is clicked' do
    before do
      click_link_or_button 'Cancel'

      wait_for_all_requests
    end

    it 'redirects to the main "Releases" page' do
      expect(page).to have_current_path(project_releases_path(project))
    end

    context 'when the URL includes a back_url query parameter' do
      let(:back_path) { project_releases_path(project, params: { page: 2 }) }
      let(:new_page_url) do
        new_project_release_path(project, params: { back_url: back_path })
      end

      it 'redirects to the page specified with back_url' do
        expect(page).to have_current_path(back_path)
      end
    end
  end

  context 'when the release notes "Preview" tab is clicked' do
    before do
      find_field('Release notes').click

      fill_release_notes('**some** _markdown_ [content](https://example.com)')

      click_on 'Preview'

      wait_for_all_requests
    end

    it 'renders a preview of the release notes markdown' do
      within('[data-testid="release-notes"]') do
        expect(page).to have_text('some markdown content')
      end
    end
  end

  def fill_out_form_and_submit
    select_new_tag_name(tag_name)

    select_create_from(branch.name)

    fill_release_title(release_title)

    select_milestone(milestone_1.title)
    select_milestone(milestone_2.title)

    fill_release_notes(release_notes)

    fill_asset_link(link_1)
    add_another_asset_link
    fill_asset_link(link_2)

    # Click on the body in order to trigger a `blur` event on the current field.
    # This triggers the form's validation to run so that the
    # "Create release" button is enabled and clickable.
    page.find('body').click

    click_button('Create release')

    wait_for_all_requests
  end

  def branch
    project.repository.branches.find { |b| b.name == 'feature' }
  end

  def commit
    branch.dereferenced_target
  end
end
