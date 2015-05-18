require 'spec_helper'

describe EmailsHelper do
  describe 'password_reset_token_valid_time' do
    def validate_time_string(time_limit, expected_string)
      Devise.reset_password_within = time_limit
      expect(password_reset_token_valid_time).to eq(expected_string)
    end

    context 'when time limit is less than 2 hours' do
      it 'should display the time in hours using a singular unit' do
        validate_time_string(1.hour, '1 hour')
      end
    end

    context 'when time limit is 2 or more hours' do
      it 'should display the time in hours using a plural unit' do
        validate_time_string(2.hours, '2 hours')
      end
    end

    context 'when time limit contains fractions of an hour' do
      it 'should round down to the nearest hour' do
        validate_time_string(96.minutes, '1 hour')
      end
    end

    context 'when time limit is 24 or more hours' do
      it 'should display the time in days using a singular unit' do
        validate_time_string(24.hours, '1 day')
      end
    end

    context 'when time limit is 2 or more days' do
      it 'should display the time in days using a plural unit' do
        validate_time_string(2.days, '2 days')
      end
    end

    context 'when time limit contains fractions of a day' do
      it 'should round down to the nearest day' do
        validate_time_string(57.hours, '2 days')
      end
    end
  end
end
