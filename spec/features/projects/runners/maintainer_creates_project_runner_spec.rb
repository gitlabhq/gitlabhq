# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Maintainer creates project runner', feature_category: :fleet_visibility do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when user views runners page', :js do
    let_it_be(:project) do
      create(:project, :allow_runner_registration_token).tap do |project|
        project.add_maintainer(user)
      end
    end

    before do
      visit project_runners_path(project)
    end

    it 'shows link with instructions on how to install GitLab Runner' do
      expect(page).to have_link(s_('Runners|New project runner'), href: new_project_runner_path(project))
    end

    it_behaves_like "shows and resets runner registration token" do
      let(:dropdown_text) { s_('Runners|Register a project runner') }
      let(:registration_token) { project.runners_token }
    end
  end

  context 'when user views new runner page', :js do
    let_it_be(:project) { create(:project) }

    before_all do
      project.add_maintainer(user)
    end

    before do
      visit new_project_runner_path(project)
    end

    it_behaves_like 'creates runner and shows register page' do
      let(:register_path_pattern) { register_project_runner_path(project, '.*') }
    end

    it_behaves_like 'shows locked field'
  end
end
