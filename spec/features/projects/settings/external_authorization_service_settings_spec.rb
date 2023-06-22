# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > External Authorization Classification Label setting',
  feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'shows the field to set a classification label' do
    stub_application_setting(external_authorization_service_enabled: true)

    visit edit_project_path(project)

    expect(page).to have_selector('#project_external_authorization_classification_label')
  end
end
