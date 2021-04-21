# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User wants to add a .gitlab-ci.yml file' do
  include Spec::Support::Helpers::Features::EditorLiteSpecHelpers

  let_it_be(:namespace) { create(:namespace) }

  let(:project) { create(:project, :repository, namespace: namespace) }

  before do
    sign_in project.owner
    stub_experiment(ci_syntax_templates_b: experiment_active)
    stub_experiment_for_subject(ci_syntax_templates_b: in_experiment_group)

    visit project_new_blob_path(project, 'master', file_name: '.gitlab-ci.yml')
  end

  context 'when experiment is not active' do
    let(:experiment_active) { false }
    let(:in_experiment_group) { false }

    it 'does not show the "Learn CI/CD syntax" template dropdown' do
      expect(page).not_to have_css('.gitlab-ci-syntax-yml-selector')
    end
  end

  context 'when experiment is active' do
    let(:experiment_active) { true }

    context 'when the user is in the control group' do
      let(:in_experiment_group) { false }

      it 'does not show the "Learn CI/CD syntax" template dropdown' do
        expect(page).not_to have_css('.gitlab-ci-syntax-yml-selector')
      end
    end

    context 'when the user is in the experimental group' do
      let(:in_experiment_group) { true }

      it 'allows the user to pick a "Learn CI/CD syntax" template from the dropdown', :js do
        expect(page).to have_css('.gitlab-ci-syntax-yml-selector')

        find('.js-gitlab-ci-syntax-yml-selector').click

        wait_for_requests

        within '.gitlab-ci-syntax-yml-selector' do
          find('.dropdown-input-field').set('Artifacts example')
          find('.dropdown-content .is-focused', text: 'Artifacts example').click
        end

        wait_for_requests

        expect(page).to have_css('.gitlab-ci-syntax-yml-selector .dropdown-toggle-text', text: 'Learn CI/CD syntax')
        expect(editor_get_value).to have_content('You can use artifacts to pass data to jobs in later stages.')
      end

      context 'when the group is created longer than 90 days ago' do
        let(:namespace) { create(:namespace, created_at: 91.days.ago) }

        it 'does not show the "Learn CI/CD syntax" template dropdown' do
          expect(page).not_to have_css('.gitlab-ci-syntax-yml-selector')
        end
      end
    end
  end
end
