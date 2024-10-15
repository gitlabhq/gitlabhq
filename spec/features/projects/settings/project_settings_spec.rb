# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects settings', feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }

  let(:user) { project.first_owner }
  let(:panel) { find_by_testid('advanced-settings-content', match: :first) }
  let(:button) { panel.find('.btn.gl-button.js-settings-toggle') }
  let(:title) { panel.find('.js-settings-toggle', match: :first) }

  before do
    sign_in(user)
    visit edit_project_path(project)
  end

  it 'can toggle sections by clicking the title or button', :js do
    expect_toggle_state(:expanded)

    button.click

    expect_toggle_state(:collapsed)

    button.click

    expect_toggle_state(:expanded)

    title.click

    expect_toggle_state(:collapsed)

    title.click

    expect_toggle_state(:expanded)
  end

  context 'forking enabled', :js do
    it 'toggles forking enabled / disabled' do
      visit edit_project_path(project)

      forking_enabled_input = find('input[name="project[project_feature_attributes][forking_access_level]"]', visible: :hidden)
      forking_enabled_button = find('[data-for="project[project_feature_attributes][forking_access_level]"] .gl-toggle')

      expect(forking_enabled_input.value).to eq('20')

      # disable by clicking toggle
      forking_enabled_button.click
      within_testid('visibility-features-permissions-content') do
        find_by_testid('project-features-save-button').click
      end
      wait_for_requests

      expect(forking_enabled_input.value).to eq('0')
    end
  end

  context 'default award emojis', :js do
    it 'shows award emojis by default' do
      visit edit_project_path(project)

      default_award_emojis_input = find('input[name="project[project_setting_attributes][show_default_award_emojis]"]', visible: :hidden)

      expect(default_award_emojis_input.value).to eq('true')
    end

    it 'disables award emojis when the checkbox is toggled off' do
      visit edit_project_path(project)

      default_award_emojis_input = find('input[name="project[project_setting_attributes][show_default_award_emojis]"]', visible: :hidden)
      default_award_emojis_checkbox = find('input[name="project[project_setting_attributes][show_default_award_emojis]"][type=checkbox]')

      expect(default_award_emojis_input.value).to eq('true')

      default_award_emojis_checkbox.click

      expect(default_award_emojis_input.value).to eq('false')

      within_testid('visibility-features-permissions-content') do
        find_by_testid('project-features-save-button').click
      end
      wait_for_requests

      expect(default_award_emojis_input.value).to eq('false')
    end
  end

  def expect_toggle_state(state)
    is_collapsed = state == :collapsed

    expect(panel).to have_css(is_collapsed ? '.settings-toggle[aria-label^="Expand"]' : '.settings-toggle[aria-label^="Collapse"]')

    expect(panel[:class]).send(is_collapsed ? 'not_to' : 'to', include('expanded'))
  end
end
