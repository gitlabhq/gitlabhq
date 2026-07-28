# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Job token permissions', :js, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  it 'shows the job token permissions settings' do
    visit project_settings_ci_cd_path(project)

    within_testid 'job-token-permissions-content' do
      expect(page).to have_content('Job token permissions')
    end
  end

  it 'shows the CI/CD job token allowlist' do
    visit project_settings_ci_cd_path(project)

    # The app only renders once scrolled into view (GlIntersectionObserver lazy-loads it)
    scroll_to(find_by_testid('job-token-permissions-content'), align: :center)

    within_testid 'job-token-permissions-content' do
      expect(page).to have_content('CI/CD job token allowlist')
    end
  end
end
