# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Contextual sidebar', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_path(project)
  end

  it 'shows flyout navs when collapsed or expanded apart from on the active item when expanded' do
    expect(page).not_to have_selector('.js-sidebar-collapsed')

    find('.rspec-link-pipelines').hover

    expect(page).to have_selector('.is-showing-fly-out')

    find('.rspec-project-link').hover

    expect(page).not_to have_selector('.is-showing-fly-out')

    find('.rspec-toggle-sidebar').click

    find('.rspec-link-pipelines').hover

    expect(page).to have_selector('.is-showing-fly-out')

    find('.rspec-project-link').hover

    expect(page).to have_selector('.is-showing-fly-out')
  end
end
