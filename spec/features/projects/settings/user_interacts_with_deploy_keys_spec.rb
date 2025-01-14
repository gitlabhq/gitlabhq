# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User interacts with deploy keys", :js, feature_category: :continuous_delivery do
  let(:project) { create(:project, :repository) }
  let(:user) { project.first_owner }

  before do
    sign_in(user)
  end

  shared_examples 'attaches a key' do
    it 'attaches key' do
      visit(project_deploy_keys_path(project))
      wait_for_requests

      page.within('.deploy-keys') do
        click_link(scope)

        click_button('Enable')

        expect(page).not_to have_selector('.gl-spinner')
        expect(page).to have_current_path(project_settings_repository_path(project), ignore_query: true)

        click_link('Enabled deploy keys')
        wait_for_requests

        expect(page).to have_content(deploy_key.title)
      end
    end
  end

  context 'viewing deploy keys' do
    let(:deploy_key) { create(:deploy_key) }

    context 'when project has keys' do
      before do
        create(:deploy_keys_project, project: project, deploy_key: deploy_key)
      end

      it 'shows deploy keys' do
        visit(project_deploy_keys_path(project))
        wait_for_requests

        page.within('.deploy-keys') do
          expect(page).to have_content(deploy_key.title)
        end
      end
    end

    context 'when the project has many deploy keys' do
      before do
        create(:deploy_keys_project, project: project, deploy_key: deploy_key)
        create_list(:deploy_keys_project, 5, project: project)
      end

      it 'shows pagination' do
        visit(project_deploy_keys_path(project))
        wait_for_requests

        page.within('.deploy-keys') do
          expect(page).to have_link('Next')
          expect(page).to have_link('2')
        end
      end
    end

    context 'when another project has keys' do
      let(:another_project) { create(:project) }

      before do
        create(:deploy_keys_project, project: another_project, deploy_key: deploy_key)

        another_project.add_maintainer(user)
      end

      it 'shows deploy keys' do
        visit(project_deploy_keys_path(project))
        wait_for_requests

        page.within('.deploy-keys') do
          click_link('Privately accessible deploy keys')

          expect(page).to have_content(deploy_key.title)
        end
      end
    end

    context 'when there are public deploy keys' do
      let!(:deploy_key) { create(:deploy_key, public: true) }

      it 'shows public deploy keys' do
        visit(project_deploy_keys_path(project))
        wait_for_requests

        page.within('.deploy-keys') do
          click_link('Publicly accessible deploy keys')

          expect(page).to have_content(deploy_key.title)
        end
      end
    end
  end

  context 'adding deploy keys' do
    before do
      visit(project_deploy_keys_path(project))
      wait_for_requests
    end

    it 'adds new key' do
      deploy_key_title = attributes_for(:key)[:title]
      deploy_key_body  = attributes_for(:key)[:key]

      click_button('Add new key')
      fill_in('deploy_key_title', with: deploy_key_title)
      fill_in('deploy_key_key',   with: deploy_key_body)

      click_button('Add key')

      expect(page).to have_current_path(project_settings_repository_path(project), ignore_query: true)

      page.within('.deploy-keys') do
        expect(page).to have_content(deploy_key_title)
      end
    end

    it 'click on cancel hides the form' do
      click_button('Add new key')

      expect(page).to have_css('[data-testid="crud-form"]')

      click_button('Cancel')

      expect(page).not_to have_css('[data-testid="crud-form"]')
    end
  end

  context 'attaching existing keys' do
    context 'from another project' do
      let(:another_project) { create(:project) }
      let(:deploy_key) { create(:deploy_key) }
      let(:scope) { 'Privately accessible deploy keys' }

      before do
        create(:deploy_keys_project, project: another_project, deploy_key: deploy_key)

        another_project.add_maintainer(user)
      end

      it_behaves_like 'attaches a key'
    end

    context 'when keys are public' do
      let!(:deploy_key) { create(:deploy_key, public: true) }
      let(:scope) { 'Publicly accessible deploy keys' }

      it_behaves_like 'attaches a key'
    end
  end
end
