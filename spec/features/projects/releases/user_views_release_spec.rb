# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views Release', :js, feature_category: :continuous_delivery do
  include MobileHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  let(:release) do
    create(
      :release,
      project: project,
      name: 'The first release',
      description: '**Lorem** _ipsum_ dolor sit [amet](https://example.com)'
    )
  end

  before do
    resize_window(1920, 1080)

    project.add_developer(user)

    sign_in(user)

    visit project_release_path(project, release)
  end

  after do
    restore_window_size
  end

  it_behaves_like 'page meta description', 'Lorem ipsum dolor sit amet'

  it 'renders the breadcrumbs' do
    expect(page_breadcrumbs).to include(
      { text: project.creator.name, href: user_path(project.creator) },
      { text: project.name, href: project_path(project) },
      { text: 'Releases', href: project_releases_path(project) },
      { text: release.name, href: project_release_path(project, release) }
    )
  end

  it 'renders the release details' do
    within_testid('release-block') do
      expect(page).to have_content(release.name)
      expect(page).to have_content(release.tag)
      expect(page).to have_content(release.commit.short_id)
      expect(page).to have_content('Lorem ipsum dolor sit amet')
    end
  end
end
