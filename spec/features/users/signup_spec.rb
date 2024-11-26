# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'Signup name validation' do |field, max_length, label|
  before do
    visit new_user_registration_path
  end

  describe "#{field} validation" do
    it "does not show an error border if the user's fullname length is not longer than #{max_length} characters" do
      fill_in field, with: 'u' * max_length

      expect(find('.name')).not_to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the user\'s fullname contains an emoji' do
      fill_in field, with: 'Ehsan 🦋'

      expect(find('.name')).to have_css '.gl-field-error-outline'
    end

    it "shows an error border if the user\'s fullname is longer than #{max_length} characters" do
      fill_in field, with: 'n' * (max_length + 1)

      expect(find('.name')).to have_css '.gl-field-error-outline'
    end

    it "shows an error message if the user\'s #{label} is longer than #{max_length} characters" do
      fill_in field, with: 'n' * (max_length + 1)

      expect(page).to have_content("#{label} is too long (maximum is #{max_length} characters).")
    end

    it 'shows an error message if the username contains emojis' do
      fill_in field, with: 'Ehsan 🦋'

      expect(page).to have_content("Invalid input, please avoid emoji")
    end
  end
end

RSpec.describe 'Signup', :with_current_organization, :js, feature_category: :user_management do
  include TermsHelper
  using RSpec::Parameterized::TableSyntax

  let(:new_user) { build_stubbed(:user) }

  let(:terms_text) do
    <<~TEXT.squish
      By clicking Continue or registering through a third party you accept the
      Terms of Use and acknowledge the Privacy Statement and Cookie Policy
    TEXT
  end

  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
  end

  describe 'username validation' do
    before do
      visit new_user_registration_path
    end

    it 'does not show an error border if the username is available' do
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'does not show an error border if the username contains dots (.)' do
      fill_in 'new_user_username', with: 'new.user.username'
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'does not show an error border if the username length is not longer than 255 characters' do
      fill_in 'new_user_username', with: 'u' * 255
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the username already exists' do
      existing_user = create(:user)

      fill_in 'new_user_username', with: existing_user.username
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows a success border if the username is available' do
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-success-outline'
    end

    it 'shows an error border if the username contains special characters' do
      fill_in 'new_user_username', with: 'new$user!username'
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the username is longer than 255 characters' do
      fill_in 'new_user_username', with: 'u' * 256
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error message if the username is longer than 255 characters' do
      fill_in 'new_user_username', with: 'u' * 256
      wait_for_requests

      expect(page).to have_content("Username is too long (maximum is 255 characters).")
    end

    it 'shows an error message if the username is less than 2 characters' do
      fill_in 'new_user_username', with: 'u'
      wait_for_requests

      expect(page).to have_content("Username is too short (minimum is 2 characters).")
    end

    it 'shows an error message on submit if the username contains special characters' do
      fill_in 'new_user_username', with: 'new$user!username'
      wait_for_requests

      click_button _('Continue')

      expect(page).to have_content("Please create a username with only alphanumeric characters.")
    end

    it 'shows an error border if the username contains emojis' do
      fill_in 'new_user_username', with: 'ehsan😀'

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error message if the username contains emojis' do
      fill_in 'new_user_username', with: 'ehsan😀'

      expect(page).to have_content("Invalid input, please avoid emoji")
    end

    it 'shows a pending message if the username availability is being fetched',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/31484' do
      fill_in 'new_user_username', with: 'new-user'

      expect(find('.username > .validation-pending')).not_to have_css '.hide'
    end

    it 'shows a success message if the username is available' do
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(find('.username > .validation-success')).not_to have_css '.hide'
    end

    it 'shows an error message if the username is unavailable' do
      existing_user = create(:user)

      fill_in 'new_user_username', with: existing_user.username
      wait_for_requests

      expect(find('.username > .validation-error')).not_to have_css '.hide'
    end

    it 'shows a success message if the username is corrected and then available' do
      fill_in 'new_user_username', with: 'new-user$'
      wait_for_requests
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(page).to have_content("Username is available.")
    end
  end

  context 'with no errors' do
    context 'when sending confirmation email' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'hard')
      end

      context 'when email confirmation setting is not `soft`' do
        it 'creates the user account and sends a confirmation email, and pre-fills email address after confirming' do
          visit new_user_registration_path

          expect { fill_in_sign_up_form(new_user) }.to change { User.count }.by(1)
          expect(page).to have_current_path users_almost_there_path, ignore_query: true
          expect(page).to have_content("Please check your email (#{new_user.email}) to confirm your account")

          confirm_email(new_user)

          expect(find_field('Username or primary email').value).to eq(new_user.email)
        end
      end

      context 'when email confirmation setting is `soft`' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'soft')
        end

        it 'creates the user account and sends a confirmation email' do
          visit new_user_registration_path

          expect { fill_in_sign_up_form(new_user) }.to change { User.count }.by(1)
          expect(page).to have_current_path dashboard_projects_path
        end
      end
    end

    context "when not sending confirmation email" do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'off')
      end

      it 'creates the user account and goes to dashboard' do
        visit new_user_registration_path

        fill_in_sign_up_form(new_user)

        expect(page).to have_current_path dashboard_projects_path
      end
    end

    context 'with required admin approval enabled' do
      before do
        stub_application_setting(require_admin_approval_after_user_signup: true)
      end

      it 'creates the user but does not sign them in' do
        visit new_user_registration_path

        expect { fill_in_sign_up_form(new_user) }.to change { User.count }.by(1)
        expect(page).to have_current_path new_user_session_path, ignore_query: true
        expect(page).to have_content(<<~TEXT.squish)
            You have signed up successfully. However, we could not sign you in
            because your account is awaiting approval from your GitLab administrator
        TEXT
      end
    end
  end

  context 'with errors' do
    it "displays the errors" do
      create(:user, email: new_user.email)
      visit new_user_registration_path

      fill_in_sign_up_form(new_user)

      expect(page).to have_current_path user_registration_path, ignore_query: true
      expect(page).to have_content("error prohibited this user from being saved")
      expect(page).to have_content("Email has already been taken")
    end

    it 'redisplays all fields except password' do
      create(:user, email: new_user.email)
      visit new_user_registration_path

      fill_in_sign_up_form(new_user)

      expect(page).to have_current_path user_registration_path, ignore_query: true
      expect(page.body).not_to match(/#{new_user.password}/)

      expect(find_field('First name').value).to eq(new_user.first_name)
      expect(find_field('Last name').value).to eq(new_user.last_name)
      expect(find_field('Username').value).to eq(new_user.username)
      expect(find_field('Email').value).to eq(new_user.email)
    end
  end

  context 'when terms are enforced' do
    before do
      enforce_terms
    end

    it 'renders text that the user confirms terms by signing in' do
      visit new_user_registration_path
      expect(page).to have_content(terms_text)

      fill_in_sign_up_form(new_user)

      expect(page).to have_current_path(dashboard_projects_path)
    end

    it_behaves_like 'Signup name validation', 'new_user_first_name', 127, 'First name'
    it_behaves_like 'Signup name validation', 'new_user_last_name', 127, 'Last name'
  end

  context 'when reCAPTCHA and invisible captcha are enabled' do
    before do
      stub_application_setting(invisible_captcha_enabled: true)
      stub_application_setting(recaptcha_enabled: true)
      allow_next_instance_of(RegistrationsController) do |instance|
        allow(instance).to receive(:verify_recaptcha).and_return(true)
      end
    end

    context 'when reCAPTCHA detects malicious behaviour' do
      before do
        allow_next_instance_of(RegistrationsController) do |instance|
          allow(instance).to receive(:verify_recaptcha).and_return(false)
        end
      end

      it 'prevents from signing up' do
        visit new_user_registration_path

        expect { fill_in_sign_up_form(new_user) }.not_to change { User.count }
        expect(page).to have_content(_('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'))
        expect(page).to have_content(
          "Minimum length is #{Gitlab::CurrentSettings.minimum_password_length} characters")
      end
    end

    context 'when invisible captcha detects malicious behaviour' do
      context 'with form submitted quicker than timestamp_threshold', :freeze_time do
        it 'prevents from signing up' do
          visit new_user_registration_path

          expect { fill_in_sign_up_form(new_user) }.not_to change { User.count }
          expect(page).to have_content('That was a bit too quick! Please resubmit.')
        end
      end

      context 'with honeypot field is filled' do
        it 'prevents from signing up' do
          visit new_user_registration_path

          find_field('If you are human, please ignore this field.',
            visible: false).execute_script("this.value = 'bot'")

          expect { fill_in_sign_up_form(new_user) }.not_to change { User.count }
        end
      end
    end
  end

  it 'allows visiting of a page after initial registration' do
    visit new_user_registration_path

    fill_in_sign_up_form(new_user)

    visit new_project_path

    expect(page).to have_current_path(new_project_path)
  end

  it 'does not redisplay the password' do
    create(:user, email: new_user.email)
    visit new_user_registration_path

    fill_in_sign_up_form(new_user)

    expect(page).to have_current_path user_registration_path, ignore_query: true
    expect(page.body).not_to match(/#{new_user.password}/)
  end

  context 'with invalid email' do
    it_behaves_like 'user email validation' do
      let(:path) { new_user_registration_path }
    end

    where(:email, :reason) do
      '"A"@b.co'            | 'quoted emails'
      'a @b.co'             | 'space in the local-part'
      'ab.co'               | 'no @ symbol'
      'a@b@c.co'            | 'several @ symbol'
      'a@-b.co'             | 'domain starting with hyphen'
      'a@b-.co'             | 'domain finishing with hyphen'
      'a@example_me.co'     | 'domain with underscore'
      'a@example .com' | 'space in the domain'
      'a@[123.123.123.123]' | 'IP addresses'
      'a@b.'                | 'invalid domain'
    end

    with_them do
      cause = params[:reason]
      it "doesn't accept emails with #{cause}" do
        new_user.email = email
        visit new_user_registration_path

        fill_in_sign_up_form(new_user)

        expect(page).to have_current_path new_user_registration_path
        expect(page).to have_content(_("Please provide a valid email address."))
      end
    end
  end

  context 'with valid email with top-level-domain singularities' do
    it_behaves_like 'user email validation' do
      let(:path) { new_user_registration_path }
    end

    where(:email, :reason) do
      'a@b'                 | 'no TLD'
      'a@b.c'               | 'TLD less than two characters'
    end

    with_them do
      cause = params[:reason]
      it "accept emails with #{cause} but displays a warning" do
        new_user_password_ori = new_user.password
        new_user.email = email
        new_user.password = ''
        visit new_user_registration_path

        fill_in_sign_up_form(new_user)

        expect(page).to have_current_path new_user_registration_path
        expect(page).to have_content(
          _('Email address without top-level domain. Make sure that you have entered the correct email address.')
        )

        new_user.password = new_user_password_ori
        expect { fill_in_sign_up_form(new_user) }.to change { User.count }.by(1)
      end
    end
  end

  context 'with valid email' do
    where(:email, :reason) do
      '6@b.co'                              | 'alphanumerical first character in the local-part'
      '012345678901234567890123456789@b.co' | 'long local-part'
      'a@wwww.internal-site.co.uk'          | 'several subdomains'
      'a@3w.internal-site.co.uk'            | 'several subdomains'
      'a@b.example'                         | 'valid TLD'
    end

    with_them do
      cause = params[:reason]
      it "accepts emails with #{cause}" do
        new_user.email = email
        visit new_user_registration_path

        expect { fill_in_sign_up_form(new_user) }.to change { User.count }.by(1)
      end
    end
  end
end
