# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Pages edits pages settings', :js, feature_category: :pages do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:project) { create(:project, pages_https_only: false) }
  let_it_be(:user) { create(:user) }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)

    project.add_maintainer(user)

    sign_in(user)
  end

  context 'when onboarding is not complete' do
    it 'renders onboarding instructions' do
      visit project_pages_path(project)

      expect(page).to have_content('Get started with GitLab Pages')
    end
  end

  context 'when onboarding is complete' do
    before do
      project.mark_pages_onboarding_complete
    end

    it 'shows waiting screen' do
      visit project_pages_path(project)

      expect(page).to have_content('Waiting for the Pages Pipeline to complete...')
    end
  end
end
