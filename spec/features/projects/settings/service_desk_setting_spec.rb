# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service Desk Setting', :js, :clean_gitlab_redis_cache do
  let(:project) { create(:project_empty_repo, :private, service_desk_enabled: false) }
  let(:presenter) { project.present(current_user: user) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    allow_any_instance_of(Project).to receive(:present).with(current_user: user).and_return(presenter)
    allow(::Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }
  end

  it 'shows activation checkbox' do
    visit edit_project_path(project)

    expect(page).to have_selector("#service-desk-checkbox")
  end

  context 'when service_desk_email is disabled' do
    before do
      allow(::Gitlab::ServiceDeskEmail).to receive(:enabled?).and_return(false)

      visit edit_project_path(project)
    end

    it 'shows incoming email but not project name suffix after activating' do
      find("#service-desk-checkbox").click

      wait_for_requests

      project.reload
      expect(project.service_desk_enabled).to be_truthy
      expect(project.service_desk_address).to be_present
      expect(find('[data-testid="incoming-email"]').value).to eq(project.service_desk_incoming_address)
      expect(page).not_to have_selector('#service-desk-project-suffix')
    end
  end

  context 'when service_desk_email is enabled' do
    before do
      allow(::Gitlab::ServiceDeskEmail).to receive(:enabled?) { true }
      allow(::Gitlab::ServiceDeskEmail).to receive(:address_for_key) { 'address-suffix@example.com' }

      visit edit_project_path(project)
    end

    it 'allows setting of custom address suffix' do
      find("#service-desk-checkbox").click
      wait_for_requests

      project.reload
      expect(find('[data-testid="incoming-email"]').value).to eq(project.service_desk_incoming_address)

      page.within '#js-service-desk' do
        fill_in('service-desk-project-suffix', with: 'foo')
        click_button 'Save changes'
      end

      wait_for_requests

      expect(find('[data-testid="incoming-email"]').value).to eq('address-suffix@example.com')
    end

    context 'issue description templates' do
      let_it_be(:issuable_project_template_files) do
        {
          '.gitlab/issue_templates/project-issue-bar.md' => 'Project Issue Template Bar',
          '.gitlab/issue_templates/project-issue-foo.md' => 'Project Issue Template Foo'
        }
      end

      let_it_be(:issuable_group_template_files) do
        {
          '.gitlab/issue_templates/group-issue-bar.md' => 'Group Issue Template Bar',
          '.gitlab/issue_templates/group-issue-foo.md' => 'Group Issue Template Foo'
        }
      end

      let_it_be_with_reload(:group) { create(:group)}
      let_it_be_with_reload(:project) { create(:project, :custom_repo, group: group, files: issuable_project_template_files) }
      let_it_be(:group_template_repo) { create(:project, :custom_repo, group: group, files: issuable_group_template_files) }

      before do
        stub_licensed_features(custom_file_templates_for_namespace: false, custom_file_templates: false)
        group.update_columns(file_template_project_id: group_template_repo.id)
        visit edit_project_path(project)
      end

      it_behaves_like 'issue description templates from current project only'
    end
  end
end
