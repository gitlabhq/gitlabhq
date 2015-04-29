require "spec_helper"

describe MergeRequestsHelper do
  let(:project) { create :project }
  let(:merge_request) { MergeRequest.new }
  let(:ci_service) { CiService.new }
  let(:last_commit) { Commit.new({}, project) }

  before do
    merge_request.stub(:source_project) { project }
    merge_request.stub(:last_commit) { last_commit }
    project.stub(:ci_service) { ci_service }
    last_commit.stub(:sha) { '12d65c' }
  end

  describe 'ci_build_details_path' do
    it 'does not include api credentials in a link' do
      ci_service.stub(:build_page) { "http://secretuser:secretpass@jenkins.example.com:8888/job/test1/scm/bySHA1/12d65c" }
      expect(ci_build_details_path(merge_request)).to_not match("secret")
    end
  end

  describe 'issues_sentence' do
    subject { issues_sentence(issues) }
    let(:issues) do
      [build(:issue, iid: 1), build(:issue, iid: 2), build(:issue, iid: 3)]
    end

    it { is_expected.to eq('#1, #2, and #3') }

    context 'for JIRA issues' do
      let(:issues) do
        [
          JiraIssue.new('JIRA-123', project),
          JiraIssue.new('JIRA-456', project),
          JiraIssue.new('FOOBAR-7890', project)
        ]
      end

      it { is_expected.to eq('#JIRA-123, #JIRA-456, and #FOOBAR-7890') }
    end
  end
end
