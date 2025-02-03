# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Pages edits pages settings', :js, feature_category: :pages do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be_with_reload(:project) { create(:project, :pages_published, pages_https_only: false) }
  let_it_be(:user) { create(:user) }

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)

    project.add_maintainer(user)

    sign_in(user)
  end

  context 'when user is the owner' do
    before do
      project.namespace.update!(owner: user)
    end

    context 'when pages deployed' do
      before do
        create(:pages_deployment, project: project)
      end

      it 'renders Access pages' do
        visit project_pages_path(project)

        expect(page).to have_content('Access pages')
      end

      shared_examples 'does not render access control warning' do
        it 'does not render access control warning' do
          visit project_pages_path(project)

          expect(page).not_to have_content('Access Control is enabled for this Pages website')
        end
      end

      include_examples 'does not render access control warning'

      context 'when access control is enabled in gitlab settings' do
        before do
          stub_pages_setting(access_control: true)
        end

        it 'renders access control warning' do
          visit project_pages_path(project)

          expect(page).to have_content('Access Control is enabled for this Pages website')
        end

        context 'when pages are public' do
          before do
            project.project_feature.update!(pages_access_level: ProjectFeature::PUBLIC)
          end

          include_examples 'does not render access control warning'
        end
      end

      context 'when support for external domains is disabled' do
        it 'renders message that support is disabled' do
          visit project_pages_path(project)

          expect(page).to have_content('Support for domains and certificates is disabled')
        end
      end
    end

    describe 'menu entry' do
      describe 'on the pages page' do
        it 'renders "Pages" tab' do
          visit project_pages_path(project)

          within_testid 'super-sidebar' do
            expect(page).to have_link('Pages')
          end
        end
      end

      describe 'in another menu entry under deployments' do
        context 'when pages are enabled' do
          it 'renders "Pages" tab' do
            visit project_environments_path(project)

            within_testid 'super-sidebar' do
              click_button 'Deploy'
              expect(page).to have_link('Pages')
            end
          end
        end

        context 'when pages are disabled' do
          before do
            allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
          end

          it 'does not render "Pages" tab' do
            visit project_environments_path(project)

            within_testid 'super-sidebar' do
              click_button 'Deploy'
              expect(page).not_to have_link('Pages')
            end
          end
        end
      end
    end
  end

  describe 'HTTPS settings', :https_pages_enabled do
    before do
      project.namespace.update!(owner: user)

      create(:pages_deployment, project: project)
    end

    it 'tries to change the setting' do
      visit project_pages_path(project)
      expect(page).to have_content("Force HTTPS (requires valid certificates)")

      uncheck :project_pages_https_only

      click_button 'Save'

      expect(page).to have_text('Your changes have been saved')
      expect(page).not_to have_checked_field('project_pages_https_only')
    end

    context 'setting could not be updated' do
      let(:service) { instance_double('Projects::UpdateService') }

      before do
        allow(Projects::UpdateService).to receive(:new).and_return(service)
        allow(service).to receive(:execute).and_return(status: :error, message: 'Some error has occurred')
      end

      it 'tries to change the setting' do
        visit project_pages_path(project)

        uncheck :project_pages_https_only

        click_button 'Save'

        expect(page).to have_text('Some error has occurred')
      end
    end

    context 'non-HTTPS domain exists' do
      let(:project) { create(:project, :pages_published, pages_https_only: false) }

      before do
        create(:pages_domain, :without_key, :without_certificate, project: project)
      end

      it 'the setting is disabled' do
        visit project_pages_path(project)

        expect(page).to have_field(:project_pages_https_only, disabled: true)
        expect(page).to have_button('Save')
      end
    end

    context 'HTTPS pages are disabled', :https_pages_disabled do
      it 'the setting is unavailable' do
        visit project_pages_path(project)

        expect(page).not_to have_field(:project_pages_https_only)
        expect(page).not_to have_content('Force HTTPS (requires valid certificates)')
      end
    end

    context 'when project uses subdomain namespace' do
      let_it_be_with_reload(:project) { create(:project, namespace: create(:namespace, path: 'subdomain.namespace')) }

      it 'shows warning message' do
        visit project_pages_path(project)

        expect(page).to have_content("you cannot use HTTPS with subdomains")
      end
    end
  end

  describe 'Remove page' do
    context 'when pages are deployed' do
      before do
        create(:pages_deployment, project: project)
      end

      it 'removes the pages', :sidekiq_inline do
        visit project_pages_path(project)

        expect(page).to have_link('Remove pages')

        accept_gl_confirm(button_text: 'Remove pages') { click_link 'Remove pages' }

        expect(page).to have_content('Pages were scheduled for removal')
        expect(project.reload.pages_deployed?).to be_falsey
      end
    end
  end
end
