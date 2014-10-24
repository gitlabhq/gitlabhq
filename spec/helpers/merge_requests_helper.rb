require 'spec_helper'

describe MergeRequestsHelper do
  describe :issues_sentence do
    subject { issues_sentence(issues) }
    let(:issues) do
      [build(:issue, iid: 1), build(:issue, iid: 2), build(:issue, iid: 3)]
    end

    it { should eq('#1, #2, and #3') }

    context 'for JIRA issues' do
      let(:issues) do
        [JiraIssue.new('JIRA-123'), JiraIssue.new('JIRA-456'), JiraIssue.new('FOOBAR-7890')]
      end

      it { should eq('#JIRA-123, #JIRA-456, and #FOOBAR-7890') }
    end
  end
end
