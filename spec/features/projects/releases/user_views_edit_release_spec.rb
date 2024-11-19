# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits Release', :js, feature_category: :continuous_delivery do
  include MobileHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:release) { create(:release, :with_milestones, milestones_count: 1, project: project, name: 'The first release', tag: "v1.1.0") }
  let(:release_link) { create(:release_link, release: release) }

  before do
    resize_window(1920, 1080)

    project.add_developer(user)

    sign_in(user)

    visit edit_project_release_path(project, release)

    wait_for_requests
  end

  after do
    restore_window_size
  end

  def fill_out_form_and_click(button_to_click)
    fill_in 'release-title', with: 'Updated Release title', fill_options: { clear: :backspace }
    fill_in 'release-notes', with: 'Updated Release notes'

    click_link_or_button button_to_click

    wait_for_all_requests
  end

  it 'renders the breadcrumbs' do
    within_testid('breadcrumb-links') do
      expect(page_breadcrumbs).to include(
        { text: project.creator.name, href: user_path(project.creator) },
        { text: project.name, href: project_path(project) },
        { text: 'Releases', href: project_releases_path(project) },
        { text: release.name, href: project_release_path(project, release) },
        { text: 'Edit', href: edit_project_release_path(project, release) }
      )
    end
  end

  it 'renders the edit Release form' do
    expect(page).to have_content('Releases are based on Git tags. We recommend tags that use semantic versioning, for example 1.0.0, 2.1.0-pre.')

    expect(find_field('Tag name', disabled: true).value).to eq(release.tag)
    expect(find_field('release-title').value).to eq(release.name)
    expect(find_field('release-notes').value).to eq(release.description)

    expect(page).to have_button('Save changes')
    expect(page).to have_link('Cancel')
  end

  it 'does not update the Release when "Cancel" is clicked' do
    original_name = release.name
    original_description = release.description

    fill_out_form_and_click 'Cancel'

    release.reload

    expect(release.name).to eq(original_name)
    expect(release.description).to eq(original_description)
  end

  it 'updates the Release when "Save changes" is clicked' do
    fill_out_form_and_click 'Save changes'

    release.reload

    expect(release.name).to eq('Updated Release title')
    expect(release.description).to eq('Updated Release notes')
  end

  it 'does not affect the asset link' do
    fill_out_form_and_click 'Save changes'

    expected_filepath = release_link.filepath
    release_link.reload
    expect(release_link.filepath).to eq(expected_filepath)
  end

  it 'redirects to the previous page when "Cancel" is clicked when the url includes a back_url query parameter' do
    back_path = project_releases_path(project, params: { page: 2 })
    visit edit_project_release_path(project, release, params: { back_url: back_path })

    fill_out_form_and_click 'Cancel'

    expect(page).to have_current_path(back_path)
  end

  it 'redirects to the main Releases page when "Cancel" is clicked when the url does not include a back_url query parameter' do
    fill_out_form_and_click 'Cancel'

    expect(page).to have_current_path(project_releases_path(project))
  end

  it 'redirects to the dedicated Release page when "Save changes" is clicked' do
    fill_out_form_and_click 'Save changes'

    expect(page).to have_current_path(project_release_path(project, release))
  end
end
