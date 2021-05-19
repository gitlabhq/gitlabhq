# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > Packages', :js do
  let_it_be(:project) { create(:project) }

  let(:user) { project.owner }

  before do
    sign_in(user)

    stub_config(packages: { enabled: packages_enabled })

    visit edit_project_path(project)
  end

  context 'Packages enabled in config' do
    let(:packages_enabled) { true }

    it 'displays the packages toggle button' do
      expect(page).to have_button('Packages', class: 'gl-toggle')
      expect(page).to have_selector('input[name="project[packages_enabled]"] + button', visible: true)
    end
  end

  context 'Packages disabled in config' do
    let(:packages_enabled) { false }

    it 'does not show up in UI' do
      expect(page).not_to have_button('Packages', class: 'gl-toggle')
    end
  end
end
