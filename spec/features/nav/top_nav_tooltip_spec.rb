# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'top nav tooltips', :js, feature_category: :navigation do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    visit explore_projects_path
  end

  it 'clicking new dropdown hides tooltip', :aggregate_failures,
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/382786' do
    btn = '#js-onboarding-new-project-link'

    page.find(btn).hover

    expect(page).to have_content('Create new...')

    page.find(btn).click

    expect(page).not_to have_content('Create new...')
  end
end
