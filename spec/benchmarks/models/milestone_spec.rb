require 'spec_helper'

describe Milestone, benchmark: true do
  describe '#sort_issues' do
    let(:milestone) { create(:milestone) }

    let(:issue1) { create(:issue, milestone: milestone) }
    let(:issue2) { create(:issue, milestone: milestone) }
    let(:issue3) { create(:issue, milestone: milestone) }

    let(:issue_ids) { [issue3.id, issue2.id, issue1.id] }

    benchmark_subject { milestone.sort_issues(issue_ids) }

    it { is_expected.to iterate_per_second(500) }
  end
end
