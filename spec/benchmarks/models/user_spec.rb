require 'spec_helper'

describe User, benchmark: true do
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
end
