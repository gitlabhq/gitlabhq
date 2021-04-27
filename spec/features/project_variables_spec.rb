# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project variables', :js do
  let(:user)     { create(:user) }
  let(:project)  { create(:project) }
  let(:variable) { create(:ci_variable, key: 'test_key', value: 'test_value', masked: true) }
  let(:page_path) { project_settings_ci_cd_path(project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
    project.variables << variable
    visit page_path
  end

  it_behaves_like 'variable list'

  it 'adds a new variable with an environment scope' do
    click_button('Add variable')

    page.within('#add-ci-variable') do
      find('[data-qa-selector="ci_variable_key_field"] input').set('akey')
      find('#ci-variable-value').set('akey_value')
      find('[data-testid="environment-scope"]').click
      find('[data-testid="ci-environment-search"]').set('review/*')
      find('[data-testid="create-wildcard-button"]').click

      click_button('Add variable')
    end

    wait_for_requests

    page.within('[data-testid="ci-variable-table"]') do
      expect(find('.js-ci-variable-row:first-child [data-label="Environments"]').text).to eq('review/*')
    end
  end
end
