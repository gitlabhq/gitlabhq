require 'spec_helper'

describe EmailsHelper do
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
          %{<img style="height: 50px" src="/uploads/-/system/appearance/header_logo/#{appearance.id}/dk.png" alt="Dk" />}
        )
      end
    end

    context 'there is a brand item without a logo' do
      it 'returns the default header logo' do
        create :appearance, header_logo: nil

        expect(header_logo).to eq(
          %{<img alt="GitLab" src="/images/mailers/gitlab_header_logo.gif" width="55" height="50" />}
        )
      end
    end

    context 'there is no brand item' do
      it 'returns the default header logo' do
        expect(header_logo).to eq(
          %{<img alt="GitLab" src="/images/mailers/gitlab_header_logo.gif" width="55" height="50" />}
        )
      end
    end
  end
end
