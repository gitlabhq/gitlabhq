# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Users', :with_current_organization, feature_category: :user_management do
  include Features::AdminUsersHelpers
  include Spec::Support::Helpers::ModalHelpers
  include ListboxHelpers

  let_it_be(:admin) { create(:admin, organizations: [current_organization]) }
  let_it_be_with_reload(:user) do
    create(:omniauth_user, provider: 'twitter', extern_uid: '123456', organizations: [current_organization])
  end

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  describe 'GET /admin/users', :js do
    before do
      visit admin_users_path(filter: 'active')
    end

    it "is ok" do
      expect(page).to have_current_path(admin_users_path, ignore_query: true)
    end

    it "has users list" do
      admin.reload

      expect(has_user?(text: admin.name)).to be(true)
      expect(has_user?(text: admin.created_at.strftime('%b %d, %Y'))).to be(true)
      expect(has_user?(text: user.email)).to be(true)
      expect(has_user?(text: user.name)).to be(true)
      expect(page).to have_content('Projects')

      click_user_dropdown_toggle(user.id)

      expect(page).to have_button('Block')
      expect(page).to have_button('Deactivate')
      expect(page).to have_button('Delete user')
      expect(page).to have_button('Delete user and contributions')
    end

    it 'clicking edit user takes us to edit page', :aggregate_failures do
      within_testid("user-actions-#{user.id}") do
        click_link 'Edit'
      end

      expect(page).to have_content('Name')
      expect(page).to have_content('Password')
    end

    it 'shows the user popover on hover', :js do
      expect(has_testid?('user-popover', count: 0)).to eq(true)

      within('body.page-initialised') do
        find_link(user.email).hover

        within_testid('user-popover') do
          expect(page).to have_content user.name
          expect(page).to have_content user.username
          expect(page).to have_button 'Follow'
        end
      end
    end

    context 'user project count' do
      before do
        create(:project, maintainers: admin)
      end

      it 'displays count of users projects' do
        visit admin_users_path

        expect(find_by_testid("user-project-count-#{admin.id}").text).to eq("1")
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

        expect(has_user?(text: 'Foo Bar')).to be(true)
        expect(has_user?(text: 'Foo Baz')).to be(true)
        expect(has_user?(text: 'Dmitriy')).to be(false)
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
        expect(has_user?(text: 'Dmitriy')).to be(false)
        expect(first_row.text).to include('Foo Bar')
        expect(second_row.text).to include('Foo Baz')
      end

      it 'searches with respect of sorting' do
        visit admin_users_path(sort: 'name_asc', search_query: 'Foo')

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
      it 'filters by users who have enabled 2FA' do
        user_2fa = create(:user, :two_factor)

        visit admin_users_path(filter: 'two_factor_enabled')

        expect(has_user?(text: user_2fa.email)).to be(true)
        expect(all_users.length).to be(1)
      end

      it 'filters users who have not enabled 2FA' do
        visit admin_users_path(filter: 'two_factor_disabled')

        expect(has_user?(text: user.email)).to be(true)
        expect(has_user?(text: admin.email)).to be(true)
        expect(all_users.length).to be(2)
      end
    end

    describe 'Pending approval filter' do
      it 'counts users who are pending approval' do
        create_list(:user, 2, :blocked_pending_approval)

        visit admin_users_path(filter: 'blocked_pending_approval')

        expect(all_users.length).to be(2)
      end

      it 'filters by users who are pending approval' do
        blocked_user = create(:user, :blocked_pending_approval)

        visit admin_users_path(filter: 'blocked_pending_approval')

        expect(has_user?(text: blocked_user.email)).to be(true)
        expect(all_users.length).to be(1)
      end
    end

    context 'when blocking/unblocking a user' do
      it 'shows confirmation and allows blocking and unblocking', :js do
        expect(has_user?(text: user.email)).to be(true)

        click_action_in_user_dropdown(user.id, 'Block')

        wait_for_requests

        expect(page).to have_content('Block user')
        expect(page).to have_content('Blocking user has the following effects')
        expect(page).to have_content('User will not be able to login')
        expect(page).to have_content('Owned groups will be left')

        find('.modal-footer button', text: 'Block').click

        wait_for_requests

        expect(page).to have_content('Successfully blocked')
        expect(has_user?(text: user.email)).to be(false)

        visit admin_users_path(filter: 'blocked')

        wait_for_requests

        expect(has_user?(text: user.email)).to be(true)

        click_action_in_user_dropdown(user.id, 'Unblock')

        expect(page).to have_content('Unblock user')
        expect(page).to have_content('You can always block their account again if needed.')

        find('.modal-footer button', text: 'Unblock').click

        wait_for_requests

        expect(page).to have_content('Successfully unblocked')
        expect(has_user?(text: user.email)).to be(false)
      end
    end

    context 'when deactivating/re-activating a user' do
      it 'shows confirmation and allows deactivating and re-activating', :js do
        expect(has_user?(text: user.email)).to be(true)

        click_action_in_user_dropdown(user.id, 'Deactivate')

        expect(page).to have_content('Deactivate user')
        expect(page).to have_content('Deactivating a user has the following effects')
        expect(page).to have_content('The user will be logged out')
        expect(page).to have_content('Personal projects, group and user history will be left intact')

        find('.modal-footer button', text: 'Deactivate').click

        wait_for_requests

        expect(page).to have_content('Successfully deactivated')
        expect(page).not_to have_content(user.email)

        visit admin_users_path(filter: 'deactivated')

        wait_for_requests

        expect(has_user?(text: user.email)).to be(true)

        click_action_in_user_dropdown(user.id, 'Activate')

        expect(page).to have_content('Activate user')
        expect(page).to have_content('You can always deactivate their account again if needed.')

        find('.modal-footer button', text: 'Activate').click

        wait_for_requests

        expect(page).to have_content('Successfully activated')
        expect(has_user?(text: user.email)).to be(false)
      end
    end

    context 'when a user is locked', time_travel_to: '2020-02-25 10:30:45 -0700' do
      let_it_be(:locked_user) { create(:user, locked_at: DateTime.parse('2020-02-25 10:30:00 -0700')) }

      it "displays `Locked` badge next to user" do
        expect(page).to have_content("#{locked_user.name} Locked")
      end

      it 'allows a user to be unlocked from the `User administration dropdown', :js do
        accept_gl_confirm("Unlock user #{locked_user.name}?", button_text: 'Unlock') do
          click_action_in_user_dropdown(locked_user.id, 'Unlock')
        end

        expect(page).not_to have_content("#{locked_user.name} Locked")
      end
    end

    describe 'users pending approval' do
      it 'sends a welcome email and a password reset email to the user upon admin approval', :sidekiq_inline do
        user = create(:user, :blocked_pending_approval, created_by_id: admin.id)

        visit admin_users_path(filter: 'blocked_pending_approval')

        click_user_dropdown_toggle(user.id)

        find_by_testid('approve').click

        expect(page).to have_content("Approve user #{user.name}?")

        within_modal do
          perform_enqueued_jobs do
            click_button 'Approve'
          end
        end

        expect(page).to have_content('Successfully approved')

        welcome_email = ActionMailer::Base.deliveries.find { |m| m.subject == 'Welcome to GitLab!' }
        expect(welcome_email.to).to eq([user.email])
        expect(welcome_email.text_part.body).to have_content('Your GitLab account request has been approved!')

        password_reset_email = ActionMailer::Base.deliveries.find { |m| m.subject == 'Account was created for you' }
        expect(password_reset_email.to).to eq([user.email])
        expect(password_reset_email.text_part.body).to have_content('Click here to set your password')

        expect(ActionMailer::Base.deliveries.count).to eq(2)
      end
    end

    describe 'internal users' do
      context 'when showing a `Ghost User`' do
        let_it_be(:ghost_user) { create(:user, :ghost) }

        it 'does not render actions dropdown' do
          expect(page).not_to have_css(
            "[data-testid='user-actions-#{ghost_user.id}'] [data-testid='user-actions-dropdown-toggle']")
        end
      end

      context 'when showing a `Bot User`' do
        let_it_be(:bot_user) { create(:user, user_type: :alert_bot) }

        it 'does not render actions dropdown' do
          expect(page).not_to have_css(
            "[data-testid='user-actions-#{bot_user.id}'] [data-testid='user-actions-dropdown-toggle']")
        end
      end
    end

    context 'user group count', :js do
      before do
        create(:group, developers: admin)
        create(:project, group: create(:group), reporters: admin)
      end

      it 'displays count of the users authorized groups' do
        visit admin_users_path

        wait_for_requests

        within_testid("user-group-count-#{admin.id}") do
          expect(page).to have_content('2')
        end
      end
    end

    context 'user pending approval' do
      it 'shows user info', :aggregate_failures do
        user = create(:user, :blocked_pending_approval)

        visit admin_users_path(filter: 'blocked_pending_approval')
        click_link user.name

        expect(page).to have_content(user.name)
        expect(page).to have_content('Pending approval')

        click_user_dropdown_toggle(user.id)

        expect(page).to have_button('Approve')
        expect(page).to have_button('Reject')
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
      expect { click_button 'Create user' }.to change { User.count }.by(1)
    end

    it 'applies defaults to user' do
      click_button 'Create user'
      user = User.find_by(username: 'bang')
      expect(user.projects_limit)
        .to eq(Gitlab.config.gitlab.default_projects_limit)
      expect(user.can_create_group)
        .to eq(Gitlab::CurrentSettings.can_create_group)
      expect(user.private_profile)
        .to eq(Gitlab::CurrentSettings.user_defaults_to_private_profile)
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
        expect { click_button 'Create user' }.to change { User.count }.by(0)

        expect(page).to have_content('The form contains the following error')
        expect(page).to have_content('Username can contain only letters, digits')
      end
    end

    context 'when organization access level is set', :js do
      before do
        within_testid 'organization-section' do
          select_from_listbox 'Owner', from: 'User'
        end
        click_button 'Create user'
      end

      it 'assigns correct organization access level', :js do
        user = User.find_by(username: 'bang')
        organization_user = Organizations::OrganizationUser
          .find_by(user_id: user.id, organization_id: current_organization.id)

        expect(organization_user.access_level).to eq('owner')
      end
    end

    context 'when instance has multiple organizations', :js do
      let_it_be(:organization) { create(:organization, name: 'New Organization', users: [admin]) }

      it 'creates user in the selected organization' do
        within_testid 'organization-section' do
          select_from_listbox 'New Organization', from: current_organization.name
        end

        expect { click_button 'Create user' }.to change { organization.users.count }.by(1)
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
    let_it_be(:group) { create(:group, developers: user) }
    let_it_be(:project) { create(:project, group: group) }

    before do
      visit projects_admin_user_path(user)
    end

    it 'lists groups' do
      within(:css, '.gl-mb-3 + .gl-card') do
        expect(page).to have_content 'Groups'
        expect(page).to have_link group.name, href: admin_group_path(group)
      end
    end

    it 'allows navigation to the group details' do
      within(:css, '.gl-mb-3 + .gl-card') do
        click_link group.name
      end
      expect(page).to have_content group.name
      expect(page).to have_content project.name
    end

    it 'shows the group access level' do
      within(:css, '.gl-mb-3 + .gl-card') do
        expect(page).to have_content 'Developer'
      end
    end

    it 'allows group membership to be revoked', :js do
      page.within(first('.group_member')) do
        find_by_testid('remove-user').click
      end

      accept_gl_confirm(button_text: 'Remove')

      wait_for_requests

      expect(page).not_to have_selector('.group_member')
    end
  end

  describe 'show breadcrumbs', :js do
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

      check_breadcrumb('New identity')

      visit admin_user_identities_path(user)

      find('.table').find(:link, 'Edit').click

      check_breadcrumb('Edit')
    end

    def check_breadcrumb(content)
      expect(find_by_testid('breadcrumb-links').find('li:last-of-type')).to have_content(content)
    end
  end

  describe 'GET /admin/users/:id/edit' do
    before do
      visit edit_admin_user_path(user)
    end

    it 'shows all breadcrumbs', :js do
      expect(page_breadcrumbs).to eq([
        { text: 'Admin area', href: admin_root_path },
        { text: 'Users', href: admin_users_path },
        { text: user.name, href: admin_user_path(user) },
        { text: 'Edit', href: edit_admin_user_path(user) }
      ])
    end

    describe 'Update user' do
      before do
        fill_in 'user_name', with: 'Big Bang'
        fill_in 'user_email', with: 'bigbang@mail.com'
        fill_in 'user_password', with: 'AValidPassword1'
        fill_in 'user_password_confirmation', with: 'AValidPassword1'
        choose 'user_access_level_admin'
        check 'Private profile'
      end

      it 'shows page with new data' do
        click_button 'Save changes'

        expect(page).to have_content('bigbang@mail.com')
        expect(page).to have_content('Big Bang')
      end

      it 'changes user entry' do
        click_button 'Save changes'

        user.reload
        expect(user.name).to eq('Big Bang')
        expect(user.admin?).to be_truthy
        expect(user.password_expires_at).to be <= Time.zone.now
        expect(user.private_profile).to eq(true)
      end

      context 'when updating the organization access level', :js do
        it 'updates the user organization access level' do
          organization_user = Organizations::OrganizationUser
            .find_by(user_id: user.id, organization_id: current_organization.id)

          expect do
            within_testid 'organization-section' do
              select_from_listbox 'Owner', from: 'User'
            end

            click_button 'Save changes'
          end.to change { organization_user.reload.access_level }.from('default').to('owner')
        end
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
    all_users[0]
  end

  def second_row
    all_users[1]
  end

  def all_users
    page.all('tbody[role="rowgroup"] > tr')
  end

  def has_user?(**kwargs)
    page.has_selector?('tbody[role="rowgroup"] > tr', **kwargs)
  end

  def sort_by(option)
    within_testid('filtered-search-block') do
      find('.gl-new-dropdown').click
      select_listbox_item(option)
    end
  end
end
