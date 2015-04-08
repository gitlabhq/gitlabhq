require 'spec_helper'

describe MergeRequestsHelper do
  describe :issues_sentence do
    subject { issues_sentence(issues) }
    let(:issues) do
      [build(:issue, iid: 1), build(:issue, iid: 2), build(:issue, iid: 3)]
    end

    it { is_expected.to eq('#1, #2, and #3') }
  end

  describe '#merge_request_message' do
    subject { merge_request_message(merge_request) }
    let(:expected_message) do
      'This will merge bruce into wayne. Are you ABSOLUTELY sure?'
    end
    let(:merge_request) do
      create(:merge_request, source_branch: 'bruce', target_branch: 'wayne' )
    end

    it { is_expected.to eq(expected_message) }
  end
end
