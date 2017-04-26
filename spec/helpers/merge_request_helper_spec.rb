require "spec_helper"

describe MergeRequestsHelper do
  let(:project) { create :project }
  let(:merge_request) { MergeRequest.new }
  let(:ci_service) { CiService.new }
  let(:last_commit) { Commit.new({}, project) }

  before do
    allow(merge_request).to receive(:source_project) { project }
    allow(merge_request).to receive(:last_commit) { last_commit }
    allow(project).to receive(:ci_service) { ci_service }
    allow(last_commit).to receive(:sha) { '12d65c' }
  end

  describe 'ci_build_details_path' do
    it 'does not include api credentials in a link' do
      allow(ci_service).to receive(:build_page) { "http://secretuser:secretpass@jenkins.example.com:8888/job/test1/scm/bySHA1/12d65c" }
      expect(ci_build_details_path(merge_request)).not_to match("secret")
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
          ExternalIssue.new('JIRA-123', project),
          ExternalIssue.new('JIRA-456', project),
          ExternalIssue.new('FOOBAR-7890', project)
        ]
      end

      it { is_expected.to eq('FOOBAR-7890, JIRA-123, and JIRA-456') }
    end
  end

  describe 'render_items_list' do
    it "returns one item in the list" do
      expect(render_items_list(["user"])).to eq("user")
    end

    it "returns two items in the list" do
      expect(render_items_list(%w(user user1))).to eq("user and user1")
    end

    it "returns three items in the list" do
      expect(render_items_list(%w(user user1 user2))).to eq("user, user1 and user2")
    end
  end
end
