# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EmailsHelper do
  describe 'closure_reason_text' do
    context 'when given a MergeRequest' do
      let(:merge_request) { create(:merge_request) }
      let(:merge_request_presenter) { merge_request.present }

      context 'when user can read merge request' do
        let(:user) { create(:user) }

        before do
          merge_request.project.add_developer(user)
          self.instance_variable_set(:@recipient, user)
          self.instance_variable_set(:@project, merge_request.project)
        end

        context "and format is text" do
          it "returns plain text" do
            expect(helper.closure_reason_text(merge_request, format: :text)).to eq("via merge request #{merge_request.to_reference} (#{merge_request_presenter.web_url})")
          end
        end

        context "and format is HTML" do
          it "returns HTML" do
            expect(helper.closure_reason_text(merge_request, format: :html)).to eq("via merge request #{link_to(merge_request.to_reference, merge_request_presenter.web_url)}")
          end
        end

        context "and format is unknown" do
          it "returns plain text" do
            expect(helper.closure_reason_text(merge_request, format: 'unknown')).to eq("via merge request #{merge_request.to_reference} (#{merge_request_presenter.web_url})")
          end
        end
      end

      context 'when user cannot read merge request' do
        it "does not have link to merge request" do
          expect(helper.closure_reason_text(merge_request)).to be_empty
        end
      end
    end

    context 'when given a String' do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:closed_via) { "5a0eb6fd7e0f133044378c662fcbbc0d0c16dbfa" }

      context 'when user can read commits' do
        before do
          project.add_developer(user)
          self.instance_variable_set(:@recipient, user)
          self.instance_variable_set(:@project, project)
        end

        it "returns plain text" do
          expect(closure_reason_text(closed_via)).to eq("via #{closed_via}")
        end
      end

      context 'when user cannot read commits' do
        it "returns plain text" do
          expect(closure_reason_text(closed_via)).to be_empty
        end
      end
    end

    context 'when not given anything' do
      it "returns empty string" do
        expect(closure_reason_text(nil)).to eq("")
      end
    end
  end

  describe 'notification_reason_text' do
    subject { helper.notification_reason_text(reason_code) }

    using RSpec::Parameterized::TableSyntax

    where(:reason_code, :reason_text) do
      NotificationReason::OWN_ACTIVITY | ' of your activity '
      NotificationReason::ASSIGNED     | ' you have been assigned an item '
      NotificationReason::MENTIONED    | ' you have been mentioned '
      ""                               | ' of your account '
      nil                              | ' of your account '
    end

    with_them do
      it { is_expected.to start_with "You're receiving this email because" }

      it { is_expected.to include reason_text }

      it { is_expected.to end_with "on #{Gitlab.config.gitlab.host}." }
    end
  end

  describe 'sanitize_name' do
    context 'when name contains a valid URL string' do
      it 'returns name with `.` replaced with `_` to prevent mail clients from auto-linking URLs' do
        expect(sanitize_name('https://about.gitlab.com')).to eq('https://about_gitlab_com')
        expect(sanitize_name('www.gitlab.com')).to eq('www_gitlab_com')
        expect(sanitize_name('//about.gitlab.com/handbook/security/#best-practices')).to eq('//about_gitlab_com/handbook/security/#best-practices')
      end

      it 'returns name as it is when it does not contain a URL' do
        expect(sanitize_name('Foo Bar')).to eq('Foo Bar')
      end
    end
  end

  describe '#say_hi' do
    let(:user) { create(:user, name: 'John') }

    it 'returns the greeting message for the given user' do
      expect(say_hi(user)).to eq('Hi John!')
    end
  end

  describe '#say_hello' do
    let(:user) { build(:user, name: 'John') }

    it 'returns the greeting message for the given user' do
      expect(say_hello(user)).to eq('Hello, John!')
    end
  end

  describe '#two_factor_authentication_disabled_text' do
    it 'returns the message that 2FA is disabled' do
      expect(two_factor_authentication_disabled_text).to eq(
        _('Two-factor authentication has been disabled for your GitLab account.')
      )
    end
  end

  describe '#re_enable_two_factor_authentication_text' do
    context 'format is html' do
      it 'returns HTML' do
        expect(re_enable_two_factor_authentication_text(format: :html)).to eq(
          "If you want to re-enable two-factor authentication, visit the " \
          "#{link_to('two-factor authentication settings', profile_two_factor_auth_url, target: :_blank, rel: 'noopener noreferrer')} page."
        )
      end
    end

    context 'format is not specified' do
      it 'returns text' do
        expect(re_enable_two_factor_authentication_text).to eq(
          "If you want to re-enable two-factor authentication, visit #{profile_two_factor_auth_url}"
        )
      end
    end
  end

  describe '#admin_changed_password_text' do
    context 'format is html' do
      it 'returns HTML' do
        expect(admin_changed_password_text(format: :html)).to eq(
          "An administrator changed the password for your GitLab account on " \
          "#{link_to(Gitlab.config.gitlab.url, Gitlab.config.gitlab.url, target: :_blank, rel: 'noopener noreferrer')}."
        )
      end
    end

    context 'format is not specified' do
      it 'returns text' do
        expect(admin_changed_password_text).to eq(
          "An administrator changed the password for your GitLab account on #{Gitlab.config.gitlab.url}."
        )
      end
    end
  end

  describe '#contact_your_administrator_text' do
    it 'returns the message to contact the administrator' do
      expect(contact_your_administrator_text).to eq(
        _('Please contact your administrator with any questions.')
      )
    end
  end

  describe 'password_reset_token_valid_time' do
    def validate_time_string(time_limit, expected_string)
      Devise.reset_password_within = time_limit
      expect(password_reset_token_valid_time).to eq(expected_string)
    end

    context 'when time limit is less than 2 hours' do
      it 'displays the time in hours using a singular unit' do
        validate_time_string(1.hour, '1 hour')
      end
    end

    context 'when time limit is 2 or more hours' do
      it 'displays the time in hours using a plural unit' do
        validate_time_string(2.hours, '2 hours')
      end
    end

    context 'when time limit contains fractions of an hour' do
      it 'rounds down to the nearest hour' do
        validate_time_string(96.minutes, '1 hour')
      end
    end

    context 'when time limit is 24 or more hours' do
      it 'displays the time in days using a singular unit' do
        validate_time_string(24.hours, '1 day')
      end
    end

    context 'when time limit is 2 or more days' do
      it 'displays the time in days using a plural unit' do
        validate_time_string(2.days, '2 days')
      end
    end

    context 'when time limit contains fractions of a day' do
      it 'rounds down to the nearest day' do
        validate_time_string(57.hours, '2 days')
      end
    end
  end

  describe '#header_logo' do
    context 'there is a brand item with a logo' do
      it 'returns the brand header logo' do
        appearance = create :appearance, header_logo: fixture_file_upload('spec/fixtures/dk.png')

        expect(header_logo).to eq(
          %{<img style="height: 50px" src="/uploads/-/system/appearance/header_logo/#{appearance.id}/dk.png" />}
        )
      end
    end

    context 'there is a brand item without a logo' do
      it 'returns the default header logo' do
        create :appearance, header_logo: nil

        expect(header_logo).to match(
          %r{<img alt="GitLab" src="/images/mailers/gitlab_header_logo\.(?:gif|png)" width="\d+" height="\d+" />}
        )
      end
    end

    context 'there is no brand item' do
      it 'returns the default header logo' do
        expect(header_logo).to match(
          %r{<img alt="GitLab" src="/images/mailers/gitlab_header_logo\.(?:gif|png)" width="\d+" height="\d+" />}
        )
      end
    end
  end

  describe '#create_list_id_string' do
    using RSpec::Parameterized::TableSyntax

    where(:full_path, :list_id_path) do
      "01234"  | "01234"
      "5/0123" | "012.."
      "45/012" | "012.."
      "012"    | "012"
      "23/01"  | "01.23"
      "2/01"   | "01.2"
      "234/01" | "01.."
      "4/2/0"  | "0.2.4"
      "45/2/0" | "0.2.."
      "5/23/0" | "0.."
      "0-2/5"  | "5.0-2"
      "0_2/5"  | "5.0-2"
      "0.2/5"  | "5.0-2"
    end

    with_them do
      it 'ellipcizes different variants' do
        project = double("project")
        allow(project).to receive(:full_path).and_return(full_path)
        allow(project).to receive(:id).and_return(12345)
        # Set a max length that gives only 5 chars for the project full path
        max_length = "12345..#{Gitlab.config.gitlab.host}".length + 5
        list_id = create_list_id_string(project, max_length)

        expect(list_id).to eq("12345.#{list_id_path}.#{Gitlab.config.gitlab.host}")
        expect(list_id).to satisfy { |s| s.length <= max_length }
      end
    end
  end

  describe 'Create realistic List-Id identifier' do
    using RSpec::Parameterized::TableSyntax

    where(:full_path, :list_id_path) do
      "gitlab-org/gitlab-ce" | "gitlab-ce.gitlab-org"
      "project-name/subproject_name/my.project" | "my-project.subproject-name.project-name"
    end

    with_them do
      it 'produces the right List-Id' do
        project = double("project")
        allow(project).to receive(:full_path).and_return(full_path)
        allow(project).to receive(:id).and_return(12345)
        list_id = create_list_id_string(project)

        expect(list_id).to eq("12345.#{list_id_path}.#{Gitlab.config.gitlab.host}")
        expect(list_id).to satisfy { |s| s.length <= 255 }
      end
    end
  end

  describe 'header and footer messages' do
    context 'when email_header_and_footer_enabled is enabled' do
      it 'returns header and footer messages' do
        create :appearance, header_message: 'Foo', footer_message: 'Bar', email_header_and_footer_enabled: true

        aggregate_failures do
          expect(html_header_message).to eq(%{<div class="header-message" style=""><p>Foo</p></div>})
          expect(html_footer_message).to eq(%{<div class="footer-message" style=""><p>Bar</p></div>})
          expect(text_header_message).to eq('Foo')
          expect(text_footer_message).to eq('Bar')
        end
      end

      context 'when header and footer messages are empty' do
        it 'returns nil' do
          create :appearance, header_message: '', footer_message: '', email_header_and_footer_enabled: true

          aggregate_failures do
            expect(html_header_message).to eq(nil)
            expect(html_footer_message).to eq(nil)
            expect(text_header_message).to eq(nil)
            expect(text_footer_message).to eq(nil)
          end
        end
      end

      context 'when header and footer messages are nil' do
        it 'returns nil' do
          create :appearance, header_message: nil, footer_message: nil, email_header_and_footer_enabled: true

          aggregate_failures do
            expect(html_header_message).to eq(nil)
            expect(html_footer_message).to eq(nil)
            expect(text_header_message).to eq(nil)
            expect(text_footer_message).to eq(nil)
          end
        end
      end
    end

    context 'when email_header_and_footer_enabled is disabled' do
      it 'returns header and footer messages' do
        create :appearance, header_message: 'Foo', footer_message: 'Bar', email_header_and_footer_enabled: false

        aggregate_failures do
          expect(html_header_message).to eq(nil)
          expect(html_footer_message).to eq(nil)
          expect(text_header_message).to eq(nil)
          expect(text_footer_message).to eq(nil)
        end
      end
    end
  end

  describe '#change_reviewer_notification_text' do
    let(:mary) { build(:user, name: 'Mary') }
    let(:john) { build(:user, name: 'John') }
    let(:ted) { build(:user, name: 'Ted') }

    context 'to new reviewers only' do
      let(:previous_reviewers) { [] }
      let(:new_reviewers) { [john] }

      context 'with no html tag' do
        let(:expected_output) do
          'Reviewer changed to John'
        end

        it 'returns the expected output' do
          expect(change_reviewer_notification_text(new_reviewers, previous_reviewers)).to eq(expected_output)
        end
      end

      context 'with <strong> tag' do
        let(:expected_output) do
          'Reviewer changed to <strong>John</strong>'
        end

        it 'returns the expected output' do
          expect(change_reviewer_notification_text(new_reviewers, previous_reviewers, :strong)).to eq(expected_output)
        end
      end
    end

    context 'from previous reviewers to new reviewers' do
      let(:previous_reviewers) { [john, mary] }
      let(:new_reviewers) { [ted] }

      context 'with no html tag' do
        let(:expected_output) do
          'Reviewer changed from John and Mary to Ted'
        end

        it 'returns the expected output' do
          expect(change_reviewer_notification_text(new_reviewers, previous_reviewers)).to eq(expected_output)
        end
      end

      context 'with <strong> tag' do
        let(:expected_output) do
          'Reviewer changed from <strong>John and Mary</strong> to <strong>Ted</strong>'
        end

        it 'returns the expected output' do
          expect(change_reviewer_notification_text(new_reviewers, previous_reviewers, :strong)).to eq(expected_output)
        end
      end
    end

    context 'from previous reviewers to no reviewers' do
      let(:previous_reviewers) { [john, mary] }
      let(:new_reviewers) { [] }

      context 'with no html tag' do
        let(:expected_output) do
          'Reviewer changed from John and Mary to Unassigned'
        end

        it 'returns the expected output' do
          expect(change_reviewer_notification_text(new_reviewers, previous_reviewers)).to eq(expected_output)
        end
      end

      context 'with <strong> tag' do
        let(:expected_output) do
          'Reviewer changed from <strong>John and Mary</strong> to <strong>Unassigned</strong>'
        end

        it 'returns the expected output' do
          expect(change_reviewer_notification_text(new_reviewers, previous_reviewers, :strong)).to eq(expected_output)
        end
      end
    end

    context "with a <script> tag in user's name" do
      let(:previous_reviewers) { [] }
      let(:new_reviewers) { [fishy_user] }
      let(:fishy_user) { build(:user, name: "<script>alert('hi')</script>") }

      let(:expected_output) do
        'Reviewer changed to <strong>&lt;script&gt;alert(&#39;hi&#39;)&lt;/script&gt;</strong>'
      end

      it 'escapes the html tag' do
        expect(change_reviewer_notification_text(new_reviewers, previous_reviewers, :strong)).to eq(expected_output)
      end
    end

    context "with url in user's name" do
      subject(:email_helper) { Object.new.extend(described_class) }

      let(:previous_reviewers) { [] }
      let(:new_reviewers) { [fishy_user] }
      let(:fishy_user) { build(:user, name: "example.com") }

      let(:expected_output) do
        'Reviewer changed to example_com'
      end

      it "sanitizes user's name" do
        expect(email_helper).to receive(:sanitize_name).and_call_original
        expect(email_helper.change_reviewer_notification_text(new_reviewers, previous_reviewers)).to eq(expected_output)
      end
    end
  end
end
