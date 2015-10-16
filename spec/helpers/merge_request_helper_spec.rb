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
          JiraIssue.new('JIRA-123', project),
          JiraIssue.new('JIRA-456', project),
          JiraIssue.new('FOOBAR-7890', project)
        ]
      end

      it { is_expected.to eq('JIRA-123, JIRA-456, and FOOBAR-7890') }
    end
  end

  describe 'render_items_list' do
    it "returns one item in the list" do
      expect(render_items_list(["user"])).to eq("user")
    end

    it "returns two items in the list" do
      expect(render_items_list(["user", "user1"])).to eq("user and user1")
    end

    it "returns three items in the list" do
      expect(render_items_list(["user", "user1", "user2"])).to eq("user, user1 and user2")
    end
  end

  describe 'render_require_section' do
    it "returns correct value in case - one approval" do
      project.update(approvals_before_merge: 1)
      merge_request = create(:merge_request, target_project: project, source_project: project)
      expect(render_require_section(merge_request)).to eq("Requires one more approval")
    end

    it "returns correct value in case - two approval" do
      project.update(approvals_before_merge: 2)
      merge_request = create(:merge_request, target_project: project, source_project: project)
      expect(render_require_section(merge_request)).to eq("Requires 2 more approvals")
    end

    it "returns correct value in case - one approver" do
      project.update(approvals_before_merge: 1)
      merge_request = create(:merge_request, target_project: project, source_project: project)
      user = create :user
      merge_request.approvers.create(user_id: user.id)

      expect(render_require_section(merge_request)).to eq("Requires one more approval (from #{user.name})")
    end

    it "returns correct value in case - one approver and one more" do
      project.update(approvals_before_merge: 2)
      merge_request = create(:merge_request, target_project: project, source_project: project)
      user = create :user
      merge_request.approvers.create(user_id: user.id)

      expect(render_require_section(merge_request)).to eq("Requires 2 more approvals (from #{user.name} and 1 more)")
    end

    it "returns correct value in case - two approver and one more" do
      project.update(approvals_before_merge: 3)
      merge_request = create(:merge_request, target_project: project, source_project: project)
      user = create :user
      user1 = create :user
      merge_request.approvers.create(user_id: user.id)
      merge_request.approvers.create(user_id: user1.id)

      expect(render_require_section(merge_request)).to eq("Requires 3 more approvals (from #{user1.name}, #{user.name} and 1 more)")
    end
  end
end
