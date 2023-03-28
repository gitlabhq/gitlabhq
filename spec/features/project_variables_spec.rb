# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project variables', :js, feature_category: :secrets_management do
  let(:user)     { create(:user) }
  let(:project)  { create(:project) }
  let(:variable) { create(:ci_variable, key: 'test_key', value: 'test_value', masked: true) }
  let(:page_path) { project_settings_ci_cd_path(project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
    project.variables << variable
    visit page_path
    wait_for_requests
  end

  context 'when ci_variables_pages FF is enabled' do
    it_behaves_like 'variable list'
    it_behaves_like 'variable list pagination', :ci_variable
  end

  context 'when ci_variables_pages FF is disabled' do
    before do
      stub_feature_flags(ci_variables_pages: false)
    end

    it_behaves_like 'variable list'
  end

  it 'adds a new variable with an environment scope' do
    click_button('Add variable')

    page.within('#add-ci-variable') do
      fill_in 'Key', with: 'akey'
      find('#ci-variable-value').set('akey_value')

      click_button('All (default)')
      fill_in 'Search', with: 'review/*'
      find('[data-testid="create-wildcard-button"]').click

      click_button('Add variable')
    end

    wait_for_requests

    page.within('[data-testid="ci-variable-table"]') do
      expect(find('.js-ci-variable-row:first-child [data-label="Environments"]').text).to eq('review/*')
    end
  end
end
