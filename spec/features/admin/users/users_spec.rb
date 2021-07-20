# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Users' do
  include Spec::Support::Helpers::Features::AdminUsersHelpers

  let_it_be(:user, reload: true) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    gitlab_enable_admin_mode_sign_in(current_user)
  end

  describe 'GET /admin/users', :js do
    before do
      visit admin_users_path
    end

    it "is ok" do
      expect(current_path).to eq(admin_users_path)
    end

    it "has users list" do
      current_user.reload

      expect(page).to have_content(current_user.email)
      expect(page).to have_content(current_user.name)
      expect(page).to have_content(current_user.created_at.strftime('%e %b, %Y'))
      expect(page).to have_content(user.email)
      expect(page).to have_content(user.name)
      expect(page).to have_content('Projects')

      click_user_dropdown_toggle(user.id)

      expect(page).to have_button('Block')
      expect(page).to have_button('Deactivate')
      expect(page).to have_button('Delete user')
      expect(page).to have_button('Delete user and contributions')
    end

    it 'clicking edit user takes us to edit page', :aggregate_failures do
      page.within("[data-testid='user-actions-#{user.id}']") do
        click_link 'Edit'
      end

      expect(page).to have_content('Name')
      expect(page).to have_content('Password')
    end

    describe 'view extra user information' do
      it 'shows the user popover on hover', :js, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/11290' do
        expect(page).not_to have_selector('#__BV_popover_1__')

        first_user_link = page.first('.js-user-link')
        first_user_link.hover

        expect(page).to have_selector('#__BV_popover_1__')
      end
    end

    context 'user project count' do
      before do
        project = create(:project)
        project.add_maintainer(current_user)
      end

      it 'displays count of users projects' do
        visit admin_users_path

        expect(page.find("[data-testid='user-project-count-#{current_user.id}']").text).to eq("1")
      end
    end

    describe 'tabs' do
      it 'has multiple tabs to filter users' do
        expect(page).to have_link('Active', href: admin_users_path)
        expect(page).to have_link('Admins', href: admin_users_path(filter: 'admins'))
        expect(page).to have_link('2FA Enabled', href: admin_users_path(filter: 'two_factor_enabled'))
        expect(page).to have_link('2FA Disabled', href: admin_users_path(filter: 'two_factor_disabled'))
        expect(page).to have_link('External', href: admin_users_path(filter: 'external'))
        expect(page).to have_link('Blocked', href: admin_users_path(filter: 'blocked'))
        expect(page).to have_link('Deactivated', href: admin_users_path(filter: 'deactivated'))
        expect(page).to have_link('Without projects', href: admin_users_path(filter: 'wop'))
      end

      context '`Pending approval` tab' do
        before do
          visit admin_users_path
        end

        it 'shows the `Pending approval` tab' do
          expect(page).to have_link('Pending approval', href: admin_users_path(filter: 'blocked_pending_approval'))
        end
      end
    end

    describe 'search and sort' do
      before_all do
        create(:user, name: 'Foo Bar', last_activity_on: 3.days.ago)
        create(:user, name: 'Foo Baz', last_activity_on: 2.days.ago)
        create(:user, name: 'Dmitriy')
      end

      it 'searches users by name' do
        visit admin_users_path(search_query: 'Foo')

        expect(page).to have_content('Foo Bar')
        expect(page).to have_content('Foo Baz')
        expect(page).not_to have_content('Dmitriy')
      end

      it 'sorts users by name' do
        visit admin_users_path

        sort_by('Name')

        expect(first_row.text).to include('Dmitriy')
        expect(second_row.text).to include('Foo Bar')
      end

      it 'sorts search results only' do
        visit admin_users_path(search_query: 'Foo')

        sort_by('Name')
        expect(page).not_to have_content('Dmitriy')
        expect(first_row.text).to include('Foo Bar')
        expect(second_row.text).to include('Foo Baz')
      end

      it 'searches with respect of sorting' do
        visit admin_users_path(sort: 'Name')

        fill_in :search_query, with: 'Foo'
        click_button('Search users')

        expect(first_row.text).to include('Foo Bar')
        expect(second_row.text).to include('Foo Baz')
      end

      it 'sorts users by recent last activity' do
        visit admin_users_path(search_query: 'Foo')

        sort_by('Recent last activity')

        expect(first_row.text).to include('Foo Baz')
        expect(second_row.text).to include('Foo Bar')
      end

      it 'sorts users by oldest last activity' do
        visit admin_users_path(search_query: 'Foo')

        sort_by('Oldest last activity')

        expect(first_row.text).to include('Foo Bar')
        expect(second_row.text).to include('Foo Baz')
      end
    end

    describe 'Two-factor Authentication filters' do
      it 'counts users who have enabled 2FA' do
        create(:user, :two_factor)

        visit admin_users_path

        page.within('.filter-two-factor-enabled small') do
          expect(page).to have_content('1')
        end
      end

      it 'filters by users who have enabled 2FA' do
        user = create(:user, :two_factor)

        visit admin_users_path
        click_link '2FA Enabled'

        expect(page).to have_content(user.email)
      end

      it 'counts users who have not enabled 2FA' do
        visit admin_users_path

        page.within('.filter-two-factor-disabled small') do
          expect(page).to have_content('2') # Including admin
        end
      end

      it 'filters by users who have not enabled 2FA' do
        visit admin_users_path
        click_link '2FA Disabled'

        expect(page).to have_content(user.email)
      end
    end

    describe 'Pending approval filter' do
      it 'counts users who are pending approval' do
        create_list(:user, 2, :blocked_pending_approval)

        visit admin_users_path

        page.within('.filter-blocked-pending-approval small') do
          expect(page).to have_content('2')
        end
      end

      it 'filters by users who are pending approval' do
        user = create(:user, :blocked_pending_approval)

        visit admin_users_path
        click_link 'Pending approval'

        expect(page).to have_content(user.email)
      end
    end

    context 'when blocking/unblocking a user' do
      it 'shows confirmation and allows blocking and unblocking', :js do
        expect(page).to have_content(user.email)

        click_action_in_user_dropdown(user.id, 'Block')

        wait_for_requests

        expect(page).to have_content('Block user')
        expect(page).to have_content('Blocking user has the following effects')
        expect(page).to have_content('User will not be able to login')
        expect(page).to have_content('Owned groups will be left')

        find('.modal-footer button', text: 'Block').click

        wait_for_requests

        expect(page).to have_content('Successfully blocked')
        expect(page).not_to have_content(user.email)

        click_link 'Blocked'

        wait_for_requests

        expect(page).to have_content(user.email)

        click_action_in_user_dropdown(user.id, 'Unblock')

        expect(page).to have_content('Unblock user')
        expect(page).to have_content('You can always block their account again if needed.')

        find('.modal-footer button', text: 'Unblock').click

        wait_for_requests

        expect(page).to have_content('Successfully unblocked')
        expect(page).not_to have_content(user.email)
      end
    end

    context 'when deactivating/re-activating a user' do
      it 'shows confirmation and allows deactivating and re-activating', :js do
        expect(page).to have_content(user.email)

        click_action_in_user_dropdown(user.id, 'Deactivate')

        expect(page).to have_content('Deactivate user')
        expect(page).to have_content('Deactivating a user has the following effects')
        expect(page).to have_content('The user will be logged out')
        expect(page).to have_content('Personal projects, group and user history will be left intact')

        find('.modal-footer button', text: 'Deactivate').click

        wait_for_requests

        expect(page).to have_content('Successfully deactivated')
        expect(page).not_to have_content(user.email)

        click_link 'Deactivated'

        wait_for_requests

        expect(page).to have_content(user.email)

        click_action_in_user_dropdown(user.id, 'Activate')

        expect(page).to have_content('Activate user')
        expect(page).to have_content('You can always deactivate their account again if needed.')

        find('.modal-footer button', text: 'Activate').click

        wait_for_requests

        expect(page).to have_content('Successfully activated')
        expect(page).not_to have_content(user.email)
      end
    end

    describe 'internal users' do
      context 'when showing a `Ghost User`' do
        let_it_be(:ghost_user) { create(:user, :ghost) }

        it 'does not render actions dropdown' do
          expect(page).not_to have_css("[data-testid='user-actions-#{ghost_user.id}'] [data-testid='dropdown-toggle']")
        end
      end

      context 'when showing a `Bot User`' do
        let_it_be(:bot_user) { create(:user, user_type: :alert_bot) }

        it 'does not render actions dropdown' do
          expect(page).not_to have_css("[data-testid='user-actions-#{bot_user.id}'] [data-testid='dropdown-toggle']")
        end
      end
    end

    context 'user group count', :js do
      before do
        group = create(:group)
        group.add_developer(current_user)
        project = create(:project, group: create(:group))
        project.add_reporter(current_user)
      end

      it 'displays count of the users authorized groups' do
        wait_for_requests

        expect(page.find("[data-testid='user-group-count-#{current_user.id}']").text).to eq("2")
      end
    end
  end

  describe 'GET /admin/users/new' do
    let_it_be(:user_username) { 'bang' }

    before do
      visit new_admin_user_path
      fill_in 'user_name', with: 'Big Bang'
      fill_in 'user_username', with: user_username
      fill_in 'user_email', with: 'bigbang@mail.com'
    end

    it 'creates new user' do
      expect { click_button 'Create user' }.to change {User.count}.by(1)
    end

    it 'applies defaults to user' do
      click_button 'Create user'
      user = User.find_by(username: 'bang')
      expect(user.projects_limit)
        .to eq(Gitlab.config.gitlab.default_projects_limit)
      expect(user.can_create_group)
        .to eq(Gitlab.config.gitlab.default_can_create_group)
    end

    it 'creates user with valid data' do
      click_button 'Create user'
      user = User.find_by(username: 'bang')
      expect(user.name).to eq('Big Bang')
      expect(user.email).to eq('bigbang@mail.com')
    end

    it 'calls send mail' do
      expect_next_instance_of(NotificationService) do |instance|
        expect(instance).to receive(:new_user)
      end

      click_button 'Create user'
    end

    it 'sends valid email to user with email & password' do
      perform_enqueued_jobs do
        click_button 'Create user'
      end

      user = User.find_by(username: 'bang')
      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to have_content('Account was created')
      expect(email.text_part.body).to have_content(user.email)
      expect(email.text_part.body).to have_content('password')
    end

    context 'username contains spaces' do
      let_it_be(:user_username) { 'Bing bang' }

      it "doesn't create the user and shows an error message" do
        expect { click_button 'Create user' }.to change {User.count}.by(0)

        expect(page).to have_content('The form contains the following error')
        expect(page).to have_content('Username can contain only letters, digits')
      end
    end

    context 'with new users set to external enabled' do
      context 'with regex to match internal user email address set', :js do
        before do
          stub_application_setting(user_default_external: true)
          stub_application_setting(user_default_internal_regex: '\.internal@')

          visit new_admin_user_path
        end

        it 'automatically unchecks external for matching email' do
          expects_external_to_be_checked
          expects_warning_to_be_hidden

          fill_in 'user_email', with: 'test.internal@domain.ch'

          expects_external_to_be_unchecked
          expects_warning_to_be_shown

          fill_in 'user_email', with: 'test@domain.ch'

          expects_external_to_be_checked
          expects_warning_to_be_hidden

          uncheck 'user_external'

          expects_warning_to_be_hidden
        end

        it 'creates an internal user' do
          user_name = 'tester1'
          fill_in 'user_email', with: 'test.internal@domain.ch'
          fill_in 'user_name', with: 'tester1 name'
          fill_in 'user_username', with: user_name

          expects_external_to_be_unchecked
          expects_warning_to_be_shown

          click_button 'Create user'

          new_user = User.find_by(username: user_name)

          expect(new_user.external).to be_falsy
        end

        def expects_external_to_be_checked
          expect(find('#user_external')).to be_checked
        end

        def expects_external_to_be_unchecked
          expect(find('#user_external')).not_to be_checked
        end

        def expects_warning_to_be_hidden
          expect(find('#warning_external_automatically_set', visible: :all)[:class]).to include 'hidden'
        end

        def expects_warning_to_be_shown
          expect(find('#warning_external_automatically_set')[:class]).not_to include 'hidden'
        end
      end
    end
  end

  describe 'GET /admin/users/:id/projects' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    before do
      group.add_developer(user)

      visit projects_admin_user_path(user)
    end

    it 'lists group projects' do
      within(:css, '.gl-mb-3 + .card') do
        expect(page).to have_content 'Group projects'
        expect(page).to have_link group.name, href: admin_group_path(group)
      end
    end

    it 'allows navigation to the group details' do
      within(:css, '.gl-mb-3 + .card') do
        click_link group.name
      end
      within(:css, 'h3.page-title') do
        expect(page).to have_content "Group: #{group.name}"
      end
      expect(page).to have_content project.name
    end

    it 'shows the group access level' do
      within(:css, '.gl-mb-3 + .card') do
        expect(page).to have_content 'Developer'
      end
    end

    it 'allows group membership to be revoked', :js do
      page.within(first('.group_member')) do
        accept_confirm { find('.btn[data-testid="remove-user"]').click }
      end
      wait_for_requests

      expect(page).not_to have_selector('.group_member')
    end
  end

  describe 'show breadcrumbs' do
    it do
      visit admin_user_path(user)

      check_breadcrumb(user.name)

      visit projects_admin_user_path(user)

      check_breadcrumb(user.name)

      visit keys_admin_user_path(user)

      check_breadcrumb(user.name)

      visit admin_user_impersonation_tokens_path(user)

      check_breadcrumb(user.name)

      visit admin_user_identities_path(user)

      check_breadcrumb(user.name)

      visit new_admin_user_identity_path(user)

      check_breadcrumb('New Identity')

      visit admin_user_identities_path(user)

      find('.table').find(:link, 'Edit').click

      check_breadcrumb('Edit Identity')
    end

    def check_breadcrumb(content)
      expect(find('.breadcrumbs-sub-title')).to have_content(content)
    end
  end

  describe 'GET /admin/users/:id/edit' do
    before do
      visit edit_admin_user_path(user)
    end

    describe 'Update user' do
      before do
        fill_in 'user_name', with: 'Big Bang'
        fill_in 'user_email', with: 'bigbang@mail.com'
        fill_in 'user_password', with: 'AValidPassword1'
        fill_in 'user_password_confirmation', with: 'AValidPassword1'
        choose 'user_access_level_admin'
        click_button 'Save changes'
      end

      it 'shows page with new data' do
        expect(page).to have_content('bigbang@mail.com')
        expect(page).to have_content('Big Bang')
      end

      it 'changes user entry' do
        user.reload
        expect(user.name).to eq('Big Bang')
        expect(user.admin?).to be_truthy
        expect(user.password_expires_at).to be <= Time.now
      end
    end

    describe 'update username to non ascii char' do
      it do
        fill_in 'user_username', with: '\u3042\u3044'
        click_button('Save')

        page.within '#error_explanation' do
          expect(page).to have_content('Username')
        end

        expect(page).to have_selector(%(form[action="/admin/users/#{user.username}"]))
      end
    end
  end

  def first_row
    page.all('[role="row"]')[1]
  end

  def second_row
    page.all('[role="row"]')[2]
  end

  def sort_by(option)
    page.within('.filtered-search-block') do
      find('.dropdown-menu-toggle').click
      click_link option
    end
  end
end
