# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User deletes feature flag', :js do
  include FeatureFlagHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  let!(:feature_flag) do
    create_flag(project, 'ci_live_trace', false,
                description: 'For live trace feature')
  end

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_feature_flags_path(project))

    find('.js-feature-flag-delete-button').click
    click_button('Delete feature flag')
    expect(page).to have_current_path(project_feature_flags_path(project))
  end

  it 'user does not see feature flag' do
    expect(page).to have_no_content('ci_live_trace')
  end
end
