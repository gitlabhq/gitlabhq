# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects Auto DevOps settings', :js, feature_category: :auto_devops do
  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:toggle) { page.find('input[name="project[auto_devops_attributes][enabled]"]') }

  before do
    sign_in(user)
    visit project_settings_ci_cd_path(project, anchor: 'autodevops-settings')
  end

  context 'when toggling Auto DevOps pipelines setting' do
    it 'toggles the extra settings section' do
      extra_settings = '[data-testid="extra-auto-devops-settings"].hidden'

      expect(page).not_to have_selector(extra_settings, visible: :all)

      toggle.click

      expect(page).to have_selector(extra_settings, visible: :all)

      toggle.click

      expect(page).not_to have_selector(extra_settings, visible: :all)
    end
  end
end
