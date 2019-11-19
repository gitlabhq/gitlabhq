# frozen_string_literal: true

require 'spec_helper'

describe "Admin::Users" do
  include Spec::Support::Helpers::Features::ResponsiveTableHelpers

  let!(:user) do
    create(:omniauth_user, provider: 'twitter', extern_uid: '123456')
  end

  let!(:current_user) { create(:admin, last_activity_on: 5.days.ago) }

  before do
    sign_in(current_user)
  end

  describe "GET /admin/users" do
    before do
      visit admin_users_path
    end

    it "is ok" do
      expect(current_path).to eq(admin_users_path)
    end

    it "has users list" do
      expect(page).to have_content(current_user.email)
      expect(page).to have_content(current_user.name)
      expect(page).to have_content(current_user.created_at.strftime("%e %b, %Y"))
      expect(page).to have_content(current_user.last_activity_on.strftime("%e %b, %Y"))
      expect(page).to have_content(user.email)
      expect(page).to have_content(user.name)
      expect(page).to have_button('Block')
      expect(page).to have_button('Deactivate')
      expect(page).to have_button('Delete user')
      expect(page).to have_button('Delete user and contributions')
    end

    describe "view extra user information" do
      it 'shows the user popover on hover', :js, :quarantine do
        expect(page).not_to have_selector('#__BV_popover_1__')

        first_user_link = page.first('.js-user-link')
        first_user_link.hover

        expect(page).to have_selector('#__BV_popover_1__')
      end
    end

    describe 'search and sort' do
      before do
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
  end

  describe "GET /admin/users/new" do
    let(:user_username) { 'bang' }

    before do
      visit new_admin_user_path
      fill_in "user_name", with: "Big Bang"
      fill_in "user_username", with: user_username
      fill_in "user_email", with: "bigbang@mail.com"
    end

    it "creates new user" do
      expect { click_button "Create user" }.to change {User.count}.by(1)
    end

    it "applies defaults to user" do
      click_button "Create user"
      user = User.find_by(username: 'bang')
      expect(user.projects_limit)
        .to eq(Gitlab.config.gitlab.default_projects_limit)
      expect(user.can_create_group)
        .to eq(Gitlab.config.gitlab.default_can_create_group)
    end

    it "creates user with valid data" do
      click_button "Create user"
      user = User.find_by(username: 'bang')
      expect(user.name).to eq('Big Bang')
      expect(user.email).to eq('bigbang@mail.com')
    end

    it "calls send mail" do
      expect_next_instance_of(NotificationService) do |instance|
        expect(instance).to receive(:new_user)
      end

      click_button "Create user"
    end

    it "sends valid email to user with email & password" do
      perform_enqueued_jobs do
        click_button "Create user"
      end

      user = User.find_by(username: 'bang')
      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to have_content('Account was created')
      expect(email.text_part.body).to have_content(user.email)
      expect(email.text_part.body).to have_content('password')
    end

    context 'username contains spaces' do
      let(:user_username) { 'Bing bang' }

      it "doesn't create the user and shows an error message" do
        expect { click_button "Create user" }.to change {User.count}.by(0)

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
      end
    end
  end

  describe "GET /admin/users/:id" do
    it "has user info" do
      visit admin_users_path
      click_link user.name

      expect(page).to have_content(user.email)
      expect(page).to have_content(user.name)
      expect(page).to have_content(user.id)
      expect(page).to have_button('Deactivate user')
      expect(page).to have_button('Block user')
      expect(page).to have_button('Delete user')
      expect(page).to have_button('Delete user and contributions')
    end

    describe 'Impersonation' do
      let(:another_user) { create(:user) }

      context 'before impersonating' do
        subject { visit admin_user_path(user_to_visit) }

        let(:user_to_visit) { another_user }

        context 'for other users' do
          it 'shows impersonate button for other users' do
            subject

            expect(page).to have_content('Impersonate')
          end
        end

        context 'for admin itself' do
          let(:user_to_visit) { current_user }

          it 'does not show impersonate button for admin itself' do
            subject

            expect(page).not_to have_content('Impersonate')
          end
        end

        context 'for blocked user' do
          before do
            another_user.block
          end

          it 'does not show impersonate button for blocked user' do
            subject

            expect(page).not_to have_content('Impersonate')
          end
        end

        context 'when impersonation is disabled' do
          before do
            stub_config_setting(impersonation_enabled: false)
          end

          it 'does not show impersonate button' do
            subject

            expect(page).not_to have_content('Impersonate')
          end
        end
      end

      context 'when impersonating' do
        subject { click_link 'Impersonate' }

        before do
          visit admin_user_path(another_user)
        end

        it 'logs in as the user when impersonate is clicked' do
          subject

          expect(page.find(:css, '.header-user .profile-link')['data-user']).to eql(another_user.username)
        end

        it 'sees impersonation log out icon' do
          subject

          icon = first('.fa.fa-user-secret')
          expect(icon).not_to be nil
        end

        context 'a user with an expired password' do
          before do
            another_user.update(password_expires_at: Time.now - 5.minutes)
          end

          it 'does not redirect to password change page' do
            subject

            expect(current_path).to eq('/')
          end
        end
      end

      context 'ending impersonation' do
        subject { find(:css, 'li.impersonation a').click }

        before do
          visit admin_user_path(another_user)
          click_link 'Impersonate'
        end

        it 'logs out of impersonated user back to original user' do
          subject

          expect(page.find(:css, '.header-user .profile-link')['data-user']).to eq(current_user.username)
        end

        it 'is redirected back to the impersonated users page in the admin after stopping' do
          subject

          expect(current_path).to eq("/admin/users/#{another_user.username}")
        end

        context 'a user with an expired password' do
          before do
            another_user.update(password_expires_at: Time.now - 5.minutes)
          end

          it 'is redirected back to the impersonated users page in the admin after stopping' do
            subject

            expect(current_path).to eq("/admin/users/#{another_user.username}")
          end
        end
      end
    end

    describe 'Two-factor Authentication status' do
      it 'shows when enabled' do
        user.update_attribute(:otp_required_for_login, true)

        visit admin_user_path(user)

        expect_two_factor_status('Enabled')
      end

      it 'shows when disabled' do
        visit admin_user_path(user)

        expect_two_factor_status('Disabled')
      end

      def expect_two_factor_status(status)
        page.within('.two-factor-status') do
          expect(page).to have_content(status)
        end
      end
    end

    describe 'Email verification status' do
      let!(:secondary_email) do
        create :email, email: 'secondary@example.com', user: user
      end

      it 'displays the correct status for an unverified email address' do
        user.update(confirmed_at: nil, unconfirmed_email: user.email)
        visit admin_user_path(user)

        expect(page).to have_content("#{user.email} Unverified")

        expect(page).to have_content("#{secondary_email.email} Unverified")
      end

      it 'displays the correct status for a verified email address' do
        visit admin_user_path(user)
        expect(page).to have_content("#{user.email} Verified")

        secondary_email.confirm
        expect(secondary_email.confirmed?).to be_truthy

        visit admin_user_path(user)
        expect(page).to have_content("#{secondary_email.email} Verified")
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    before do
      visit admin_users_path
      click_link "edit_user_#{user.id}"
    end

    it "has user edit page" do
      expect(page).to have_content('Name')
      expect(page).to have_content('Password')
    end

    describe "Update user" do
      before do
        fill_in "user_name", with: "Big Bang"
        fill_in "user_email", with: "bigbang@mail.com"
        fill_in "user_password", with: "AValidPassword1"
        fill_in "user_password_confirmation", with: "AValidPassword1"
        choose "user_access_level_admin"
        click_button "Save changes"
      end

      it "shows page with new data" do
        expect(page).to have_content('bigbang@mail.com')
        expect(page).to have_content('Big Bang')
      end

      it "changes user entry" do
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

  describe "GET /admin/users/:id/projects" do
    let(:group) { create(:group) }
    let!(:project) { create(:project, group: group) }

    before do
      group.add_developer(user)

      visit projects_admin_user_path(user)
    end

    it "lists group projects" do
      within(:css, '.append-bottom-default + .card') do
        expect(page).to have_content 'Group projects'
        expect(page).to have_link group.name, href: admin_group_path(group)
      end
    end

    it 'allows navigation to the group details' do
      within(:css, '.append-bottom-default + .card') do
        click_link group.name
      end
      within(:css, 'h3.page-title') do
        expect(page).to have_content "Group: #{group.name}"
      end
      expect(page).to have_content project.name
    end

    it 'shows the group access level' do
      within(:css, '.append-bottom-default + .card') do
        expect(page).to have_content 'Developer'
      end
    end

    it 'allows group membership to be revoked', :js do
      page.within(first('.group_member')) do
        accept_confirm { find('.btn-remove').click }
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

      check_breadcrumb("New Identity")

      visit admin_user_identities_path(user)

      find('.table').find(:link, 'Edit').click

      check_breadcrumb("Edit Identity")
    end
  end

  describe 'show user attributes' do
    it do
      visit admin_users_path

      click_link user.name

      expect(page).to have_content 'Account'
      expect(page).to have_content 'Personal projects limit'
    end
  end

  describe 'remove users secondary email', :js do
    let!(:secondary_email) do
      create :email, email: 'secondary@example.com', user: user
    end

    it do
      visit admin_user_path(user.username)

      expect(page).to have_content("Secondary email: #{secondary_email.email}")

      accept_confirm { find("#remove_email_#{secondary_email.id}").click }

      expect(page).not_to have_content(secondary_email.email)
    end
  end

  describe 'show user keys' do
    let!(:key1) do
      create(:key, user: user, title: "ssh-rsa Key1", key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4FIEBXGi4bPU8kzxMefudPIJ08/gNprdNTaO9BR/ndy3+58s2HCTw2xCHcsuBmq+TsAqgEidVq4skpqoTMB+Uot5Uzp9z4764rc48dZiI661izoREoKnuRQSsRqUTHg5wrLzwxlQbl1MVfRWQpqiz/5KjBC7yLEb9AbusjnWBk8wvC1bQPQ1uLAauEA7d836tgaIsym9BrLsMVnR4P1boWD3Xp1B1T/ImJwAGHvRmP/ycIqmKdSpMdJXwxcb40efWVj0Ibbe7ii9eeoLdHACqevUZi6fwfbymdow+FeqlkPoHyGg3Cu4vD/D8+8cRc7mE/zGCWcQ15Var83Tczour Key1")
    end

    let!(:key2) do
      create(:key, user: user, title: "ssh-rsa Key2", key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQSTWXhJAX/He+nG78MiRRRn7m0Pb0XbcgTxE0etArgoFoh9WtvDf36HG6tOSg/0UUNcp0dICsNAmhBKdncp6cIyPaXJTURPRAGvhI0/VDk4bi27bRnccGbJ/hDaUxZMLhhrzY0r22mjVf8PF6dvv5QUIQVm1/LeaWYsHHvLgiIjwrXirUZPnFrZw6VLREoBKG8uWvfSXw1L5eapmstqfsME8099oi+vWLR8MgEysZQmD28M73fgW4zek6LDQzKQyJx9nB+hJkKUDvcuziZjGmRFlNgSA2mguERwL1OXonD8WYUrBDGKroIvBT39zS5d9tQDnidEJZ9Y8gv5ViYP7x Key2")
    end

    it do
      visit admin_users_path

      click_link user.name
      click_link 'SSH keys'

      expect(page).to have_content(key1.title)
      expect(page).to have_content(key2.title)

      click_link key2.title

      expect(page).to have_content(key2.title)
      expect(page).to have_content(key2.key)

      click_link 'Remove'

      expect(page).not_to have_content(key2.title)
    end
  end

  describe 'show user identities' do
    it 'shows user identities' do
      visit admin_user_identities_path(user)

      expect(page).to have_content(user.name)
      expect(page).to have_content('twitter')
    end
  end

  describe 'update user identities' do
    before do
      allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:twitter, :twitter_updated])
    end

    it 'modifies twitter identity' do
      visit admin_user_identities_path(user)

      find('.table').find(:link, 'Edit').click
      fill_in 'identity_extern_uid', with: '654321'
      select 'twitter_updated', from: 'identity_provider'
      click_button 'Save changes'

      expect(page).to have_content(user.name)
      expect(page).to have_content('twitter_updated')
      expect(page).to have_content('654321')
    end
  end

  describe 'remove user with identities' do
    it 'removes user with twitter identity' do
      visit admin_user_identities_path(user)

      click_link 'Delete'

      expect(page).to have_content(user.name)
      expect(page).not_to have_content('twitter')
    end
  end

  def check_breadcrumb(content)
    expect(find('.breadcrumbs-sub-title')).to have_content(content)
  end

  def sort_by(text)
    page.within('.user-sort-dropdown') do
      click_link text
    end
  end
end
