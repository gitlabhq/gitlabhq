# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New project from template', :js, feature_category: :groups_and_projects do
  let(:user) { create(:user) }

  before do
    stub_feature_flags(new_project_creation_form: false)
    sign_in(user)

    visit new_project_path
  end

  context 'create from template' do
    before do
      page.find('a[href="#create_from_template"]').click
      wait_for_requests
    end

    it 'shows template tabs' do
      page.within('#create-from-template-pane') do
        expect(page).to have_link('Built-in', href: '#built-in')
      end
    end
  end
end
