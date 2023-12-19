# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project settings > repositories > Branch names', :js, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  context 'when Issues are initially disabled' do
    let(:project_feature) { project.project_feature }

    before do
      project_feature.update!(issues_access_level: ProjectFeature::DISABLED)
      visit project_settings_repository_path(project)
    end

    it 'do not render the Branch names settings' do
      expect(page).not_to have_content('Branch name template')
    end
  end

  context 'when Issues are initially enabled' do
    before do
      visit project_settings_repository_path(project)
    end

    it 'shows the Branch names settings' do
      expect(page).to have_content('Branch name template')

      value = "feature-%{id}"

      within('section#branch-defaults-settings') do
        fill_in 'project[issue_branch_template]', with: value

        click_on('Save changes')
      end

      expect(project.reload.issue_branch_template).to eq(value)
      expect(page).to have_content('Branch name template')
    end
  end
end
