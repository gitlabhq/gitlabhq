# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group settings > Advanced', :with_current_organization, feature_category: :groups_and_projects do
  include SafeFormatHelper
  include ActionView::Helpers::TagHelper
  include Namespaces::DeletableHelper

  def archive_group(group, user)
    result = Namespaces::Groups::ArchiveService.new(group, user).execute

    expect(result).to be_success
  end

  let_it_be(:user) { create(:user, organization: current_organization) }
  let_it_be_with_reload(:group) { create(:group, path: 'foo', owners: [user]) }

  before do
    sign_in(user)
  end

  describe 'when the group path is changed' do
    let(:new_group_path) { "bar-#{SecureRandom.hex(4)}" }
    let(:group) { create(:group, path: "foo-#{SecureRandom.hex(4)}", owners: [user]) }
    let(:old_group_full_path) { "/#{group.path}" }
    let(:new_group_full_path) { "/#{new_group_path}" }

    it 'the group is accessible via the new path' do
      update_path(new_group_path)
      visit new_group_full_path

      expect(page).to have_current_path(new_group_full_path, ignore_query: true)
      expect(find('h1.home-panel-title')).to have_content(group.name)
    end

    it 'the old group path redirects to the new path' do
      update_path(new_group_path)
      visit old_group_full_path

      expect(page).to have_current_path(new_group_full_path, ignore_query: true)
      expect(find('h1.home-panel-title')).to have_content(group.name)
    end

    context 'with a subgroup' do
      let!(:subgroup) { create(:group, parent: group, path: 'subgroup') }
      let(:old_subgroup_full_path) { "/#{group.path}/#{subgroup.path}" }
      let(:new_subgroup_full_path) { "/#{new_group_path}/#{subgroup.path}" }

      it 'the subgroup is accessible via the new path' do
        update_path(new_group_path)
        visit new_subgroup_full_path

        expect(page).to have_current_path(new_subgroup_full_path, ignore_query: true)
        expect(find('h1.home-panel-title')).to have_content(subgroup.name)
      end

      it 'the old subgroup path redirects to the new path' do
        update_path(new_group_path)
        visit old_subgroup_full_path

        expect(page).to have_current_path(new_subgroup_full_path, ignore_query: true)
        expect(find('h1.home-panel-title')).to have_content(subgroup.name)
      end
    end

    context 'with a project', :js do
      let!(:project) { create(:project, group: group) }
      let(:old_project_full_path) { "/#{group.path}/#{project.path}" }
      let(:new_project_full_path) { "/#{new_group_path}/#{project.path}" }

      before(:context) do
        TestEnv.clean_test_path
      end

      after do
        TestEnv.clean_test_path
      end

      it 'the project is accessible via the new path' do
        update_path(new_group_path)
        visit new_project_full_path

        expect(page).to have_current_path(new_project_full_path, ignore_query: true)
        expect(find_by_testid('breadcrumb-links')).to have_content(project.name)
      end

      it 'the old project path redirects to the new path' do
        update_path(new_group_path)
        visit old_project_full_path

        expect(page).to have_current_path(new_project_full_path, ignore_query: true)
        expect(find_by_testid('breadcrumb-links')).to have_content(project.name)
      end
    end
  end

  describe 'transfer group', :js do
    let(:namespace_select) { find_by_testid('transfer-group-namespace-select') }
    let(:confirm_modal) { find_by_testid('confirm-danger-modal') }

    before do
      stub_feature_flags(groups_and_projects_async_transfer: false)
    end

    shared_examples 'can transfer the group' do
      before do
        selected_group.add_owner(user)
      end

      it 'can successfully transfer the group' do
        selected_group_path = selected_group.path

        visit edit_group_path(selected_group)
        transfer_group(selected_group, target_group)

        within_testid('breadcrumb-links') do
          expect(page).to have_content(target_group.name) if target_group # rubocop:disable RSpec/AvoidConditionalStatements -- pre-existing violation
          expect(page).to have_content(selected_group.name)
        end

        if target_group # rubocop:disable RSpec/AvoidConditionalStatements -- pre-existing violation
          expect(current_url).to include("#{target_group.path}/#{selected_group_path}")
        else
          expect(current_url).to include(selected_group_path)
        end
      end
    end

    context 'when transfering from a subgroup' do
      let(:selected_group) { create(:group, path: 'foo-subgroup', parent: group) }

      context 'when transfering to no parent group' do
        let(:target_group) { nil }

        it_behaves_like 'can transfer the group'
      end

      context 'when transfering to a parent group' do
        let(:target_group) { create(:group, path: 'foo-parentgroup') }

        before do
          target_group.add_owner(user)
        end

        it_behaves_like 'can transfer the group'
      end
    end

    context 'when transfering from a root group to a parent group' do
      let(:selected_group) { create(:group, path: 'foo-rootgroup') }
      let(:target_group) { group }

      it_behaves_like 'can transfer the group'
    end

    context 'when groups_and_projects_async_transfer flag is enabled' do
      let(:selected_group) { create(:group, path: 'foo-group', owners: [user]) }

      before do
        stub_feature_flags(groups_and_projects_async_transfer: true)

        visit edit_group_path(selected_group)
        transfer_group(selected_group, group)
      end

      it 'shows async transfer banner' do
        expect(page).to have_content(s_(
          'TransferGroup|This group is scheduled for transfer. ' \
            'Users with the Maintainer or Owner role will be notified when the transfer succeeds or fails.'
        ))
      end
    end
  end

  describe 'archive', :js do
    let_it_be_with_reload(:ancestor) { group }
    let_it_be_with_reload(:subgroup) { create(:group, parent: ancestor) }

    context 'when group is archived' do
      before do
        archive_group(subgroup, user)

        visit edit_group_path(subgroup)
      end

      it 'can unarchive group', :aggregate_failures do
        click_button s_('GroupProjectUnarchiveSettings|Unarchive')

        expect(page).to have_current_path(group_path(subgroup))
        expect(page.body).not_to include(safe_format(
          _('This group is archived. Its subgroups, projects, and data are %{strong_open}read-only%{strong_close}.'),
          tag_pair(tag.strong, :strong_open, :strong_close)
        ))
      end
    end

    context 'when ancestor is archived' do
      before do
        archive_group(ancestor, user)

        visit edit_group_path(subgroup)
      end

      it 'renders section with no active button', :aggregate_failures do
        find('[data-testid=cancel-icon]').hover

        expect(page).to have_content(s_('GroupProjectArchiveSettings|Unarchive group'))
        expect(page).to have_selector('[role="tooltip"]', text: s_(
          'GroupProjectUnarchiveSettings|To unarchive this group, you must unarchive its parent group.'
        ))

        expect(page).not_to have_button(s_('GroupProjectArchiveSettings|Archive'))
        expect(page).not_to have_button(s_('GroupProjectUnarchiveSettings|Unarchive'))
      end
    end

    context 'when group and parent is not archived' do
      before do
        visit edit_group_path(subgroup)
      end

      it 'can archive group', :aggregate_failures do
        click_button s_('GroupProjectArchiveSettings|Archive')

        expect(page).to have_current_path(group_path(subgroup))
        expect(page.body).to include(safe_format(
          _('This group is archived. Its subgroups, projects, and data are %{strong_open}read-only%{strong_close}.'),
          tag_pair(tag.strong, :strong_open, :strong_close)
        ))
      end
    end
  end

  describe 'group deletion', :js, :freeze_time do
    def remove_with_confirm(button_text, confirm_with, confirm_button_text = 'Yes, delete group')
      click_button button_text
      fill_in 'confirm_name_input', with: confirm_with
      click_button confirm_button_text
    end

    before do
      stub_application_setting(deletion_adjourned_period: 7)
    end

    context 'when group is not marked for deletion' do
      before do
        visit edit_group_path(group)
      end

      it 'allows delayed deletion' do
        remove_with_confirm('Delete', group.path)

        expect(page).to have_current_path(dashboard_groups_path, ignore_query: true)
      end
    end

    context 'when group is marked for deletion' do
      before do
        group.schedule_deletion!(transition_user: user)
        create(:group_deletion_schedule, group: group)
      end

      context 'when "Allow permanent deletion" setting is enabled' do
        before do
          stub_application_setting(usage_ping_enabled: true)
          visit edit_group_path(group)
        end

        it 'allows permanent deletion', :sidekiq_inline do
          remove_with_confirm('Delete permanently', group.path)

          # Wait for the redirect/toast before asserting on the database. Checking `Group.count`
          # immediately after the Capybara action races the async deletion request and is flaky.
          expect(page).to have_content "#{group.name} is being deleted."
          expect(Group.exists?(group.id)).to be(false)
        end
      end

      context 'when there are subgroups and projects' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:project) { create(:project, namespace: group) }

        it 'does not allow permanent deletion of subgroup' do
          visit edit_group_path(subgroup)

          deletion_date = permanent_deletion_date_formatted(group)
          expect(page).not_to have_button('Delete permanently')
          expect(page).to have_content(
            "The parent group is pending deletion. This group will be permanently deleted on #{deletion_date}."
          )
        end

        it 'does not allow permanent deletion of project' do
          visit edit_project_path(project)

          deletion_date = permanent_deletion_date_formatted(group)
          expect(page).not_to have_button('Delete permanently')
          expect(page).to have_content(
            "The parent group is pending deletion. This project will be permanently deleted on #{deletion_date}."
          )
        end
      end
    end
  end

  def update_path(new_group_path)
    visit edit_group_path(group)

    within_testid('advanced-settings-content') do
      fill_in 'group_path', with: new_group_path
      click_button 'Change group URL'
    end

    # 'Change group URL' submits a form that triggers a full-page redirect to the new edit page.
    # wait_for_requests does not wait for full-page redirects, so wait on the success flash to
    # ensure the redirect has completed before the caller issues its next visit (the in-flight
    # redirect would otherwise clobber it).
    expect(page).to have_content("Group '#{group.name}' was successfully updated.")
  end

  def transfer_group(group, destination)
    within_testid('transfer-locations-dropdown') do
      click_button s_('NamespaceTransfer|Select namespace')
      fill_in _('Search'), with: destination&.name || ''
      wait_for_requests # rubocop:disable RSpec/AvoidWaitForRequests -- pre-existing violation
      click_button(destination&.name || 'No parent group')
    end

    click_button s_('GroupSettings|Transfer group')

    page.within(confirm_modal) do
      expect(page).to have_text(
        "You are about to transfer #{group.full_path} to another namespace. " \
          "This action changes the group's path and can lead to data loss."
      )

      fill_in 'confirm_name_input', with: group.full_path
      click_button 'Transfer group'
    end
  end
end
