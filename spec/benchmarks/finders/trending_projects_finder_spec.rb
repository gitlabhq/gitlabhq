require 'spec_helper'

describe TrendingProjectsFinder, benchmark: true do
  describe '#execute' do
    let(:finder) { described_class.new }
    let(:user)   { create(:user) }

    # to_a is used to force actually running the query (instead of just building
    # it).
    benchmark_subject { finder.execute(user).non_archived.to_a }

    it { is_expected.to iterate_per_second(500) }
  end
end
