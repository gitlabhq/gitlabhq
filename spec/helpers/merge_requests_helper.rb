require 'spec_helper'

describe MergeRequestsHelper do
  describe :issues_sentence do
    subject { issues_sentence(issues) }
    let(:issues) do
      [build(:issue, iid: 1), build(:issue, iid: 2), build(:issue, iid: 3)]
    end

    it { should eq('#1, #2, and #3') }
  end
end
