# frozen_string_literal: true

require 'spec_helper'

describe 'Projects settings' do
  set(:project) { create(:project) }
  let(:user) { project.owner }
  let(:panel) { find('.general-settings', match: :first) }
  let(:button) { panel.find('.btn.js-settings-toggle') }
  let(:title) { panel.find('.settings-title') }

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
      forking_enabled_button = find('input[name="project[project_feature_attributes][forking_access_level]"] + label > button')

      expect(forking_enabled_input.value).to eq('20')

      # disable by clicking toggle
      forking_enabled_button.click
      page.within('.sharing-permissions') do
        find('input[value="Save changes"]').click
      end
      wait_for_requests

      expect(forking_enabled_input.value).to eq('0')
    end
  end

  def expect_toggle_state(state)
    is_collapsed = state == :collapsed

    expect(button).to have_content(is_collapsed ? 'Expand' : 'Collapse')
    expect(panel[:class]).send(is_collapsed ? 'not_to' : 'to', include('expanded'))
  end
end
