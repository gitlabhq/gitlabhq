require 'spec_helper'

describe User, benchmark: true do
  describe '.all' do
    before do
      10.times { create(:user) }
    end

    benchmark_subject { User.all.to_a }

    it { is_expected.to iterate_per_second(500) }
  end

  describe '.by_login' do
    before do
      %w{Alice Bob Eve}.each do |name|
        create(:user,
               email: "#{name}@gitlab.com",
               username: name,
               name: name)
      end
    end

    # The iteration count is based on the query taking little over 1 ms when
    # using PostgreSQL.
    let(:iterations) { 900 }

    describe 'using a capitalized username' do
      benchmark_subject { User.by_login('Alice') }

      it { is_expected.to iterate_per_second(iterations) }
    end

    describe 'using a lowercase username' do
      benchmark_subject { User.by_login('alice') }

      it { is_expected.to iterate_per_second(iterations) }
    end

    describe 'using a capitalized Email address' do
      benchmark_subject { User.by_login('Alice@gitlab.com') }

      it { is_expected.to iterate_per_second(iterations) }
    end

    describe 'using a lowercase Email address' do
      benchmark_subject { User.by_login('alice@gitlab.com') }

      it { is_expected.to iterate_per_second(iterations) }
    end
  end

  describe '.find_by_any_email' do
    let(:user) { create(:user) }

    describe 'using a user with only a single Email address' do
      let(:email) { user.email }

      benchmark_subject { User.find_by_any_email(email) }

      it { is_expected.to iterate_per_second(1000) }
    end

    describe 'using a user with multiple Email addresses' do
      let(:email) { user.emails.first.email }

      benchmark_subject { User.find_by_any_email(email) }

      before do
        10.times do
          user.emails.create(email: FFaker::Internet.email)
        end
      end

      it { is_expected.to iterate_per_second(1000) }
    end
  end
end
