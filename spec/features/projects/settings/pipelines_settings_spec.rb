require 'spec_helper'

describe "Projects > Settings > Pipelines settings" do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  before do
    sign_in(user)
    project.add_role(user, role)
    create(:project_auto_devops, project: project)
  end

  context 'for developer' do
    let(:role) { :developer }

    it 'to be disallowed to view' do
      visit project_settings_ci_cd_path(project)

      expect(page.status_code).to eq(404)
    end
  end

  context 'for maintainer' do
    let(:role) { :maintainer }

    it 'be allowed to change' do
      visit project_settings_ci_cd_path(project)

      fill_in('Test coverage parsing', with: 'coverage_regex')

      page.within '#js-general-pipeline-settings' do
        click_on 'Save changes'
      end

      expect(page.status_code).to eq(200)

      page.within '#js-general-pipeline-settings' do
        expect(page).to have_button('Save changes', disabled: false)
      end

      expect(page).to have_field('Test coverage parsing', with: 'coverage_regex')
    end

    it 'updates auto_cancel_pending_pipelines' do
      visit project_settings_ci_cd_path(project)

      page.check('Auto-cancel redundant, pending pipelines')
      page.within '#js-general-pipeline-settings' do
        click_on 'Save changes'
      end

      expect(page.status_code).to eq(200)

      page.within '#js-general-pipeline-settings' do
        expect(page).to have_button('Save changes', disabled: false)
      end

      checkbox = find_field('project_auto_cancel_pending_pipelines')
      expect(checkbox).to be_checked
    end

    describe 'Auto DevOps' do
      it 'update auto devops settings' do
        visit project_settings_ci_cd_path(project)

        page.within '#autodevops-settings' do
          fill_in('project_auto_devops_attributes_domain', with: 'test.com')
          page.choose('project_auto_devops_attributes_enabled_false')
          click_on 'Save changes'
        end

        expect(page.status_code).to eq(200)
        expect(project.auto_devops).to be_present
        expect(project.auto_devops).not_to be_enabled
        expect(project.auto_devops.domain).to eq('test.com')
      end

      context 'when there is a cluster with ingress and external_ip' do
        before do
          cluster = create(:cluster, projects: [project])
          cluster.create_application_ingress!(external_ip: '192.168.1.100')
        end

        it 'shows the help text with the nip.io domain as an alternative to custom domain' do
          visit project_settings_ci_cd_path(project)
          expect(page).to have_content('192.168.1.100.nip.io can be used as an alternative to a custom domain')
        end
      end

      context 'when there is no ingress' do
        before do
          create(:cluster, projects: [project])
        end

        it 'alternative to custom domain is not shown' do
          visit project_settings_ci_cd_path(project)
          expect(page).not_to have_content('can be used as an alternative to a custom domain')
        end
      end
    end
  end
end
