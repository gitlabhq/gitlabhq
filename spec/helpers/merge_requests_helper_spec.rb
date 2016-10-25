require 'spec_helper'

describe MergeRequestsHelper do
  describe 'merge_request_state_icon' do
    it 'returns the correct icon for merged' do
      merge = double(merged?: true)
      icon = helper.merge_request_state_icon(merge)

      expect(icon).to include('check')
    end

    it 'returns the correct icon for closed' do
      merge = double(merged?: false, closed?: true)
      icon = helper.merge_request_state_icon(merge)

      expect(icon).to include('times')
    end

    it 'returns the correct icon for other' do
      merge = double(merged?: false, closed?: false)
      icon = helper.merge_request_state_icon(merge)

      expect(icon).to include('circle-o')
    end

    it 'passes options to the icon helper' do
      icon = helper.merge_request_state_icon(spy, class: 'foo bar')

      expect(icon).to include('foo bar')
    end
  end

  describe 'merge_request_state' do
    it 'returns the correct state for merged' do
      merge = double(merged?: true)

      expect(helper.merge_request_state(merge)).to eq 'Merged'
    end

    it 'returns the correct state for closed' do
      merge = double(merged?: false, closed?: true)

      expect(helper.merge_request_state(merge)).to eq 'Closed'
    end

    it 'returns the correc state for other' do
      merge = double(merged?: false, closed?: false)

      expect(helper.merge_request_state(merge)).to eq 'Open'
    end
  end

  describe 'ci_build_details_path' do
    let(:project) { create :project }
    let(:merge_request) { MergeRequest.new }
    let(:ci_service) { CiService.new }
    let(:last_commit) { Ci::Pipeline.new({}) }

    before do
      allow(merge_request).to receive(:source_project).and_return(project)
      allow(merge_request).to receive(:last_commit).and_return(last_commit)
      allow(project).to receive(:ci_service).and_return(ci_service)
      allow(last_commit).to receive(:sha).and_return('12d65c')
    end

    it 'does not include api credentials in a link' do
      allow(ci_service).
        to receive(:build_page).and_return("http://secretuser:secretpass@jenkins.example.com:8888/job/test1/scm/bySHA1/12d65c")
      expect(helper.ci_build_details_path(merge_request)).not_to match("secret")
    end
  end

  describe '#issues_sentence' do
    subject { issues_sentence(issues) }
    let(:issues) do
      [build(:issue, iid: 1), build(:issue, iid: 2), build(:issue, iid: 3)]
    end

    it { is_expected.to eq('#1, #2, and #3') }

    context 'for JIRA issues' do
      let(:project) { create(:project) }
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

  describe '#format_mr_branch_names' do
    describe 'within the same project' do
      let(:merge_request) { create(:merge_request) }
      subject { format_mr_branch_names(merge_request) }

      it { is_expected.to eq([merge_request.source_branch, merge_request.target_branch]) }
    end

    describe 'within different projects' do
      let(:project) { create(:project) }
      let(:fork_project) { create(:project, forked_from_project: project) }
      let(:merge_request) { create(:merge_request, source_project: fork_project, target_project: project) }
      subject { format_mr_branch_names(merge_request) }
      let(:source_title) { "#{fork_project.path_with_namespace}:#{merge_request.source_branch}" }
      let(:target_title) { "#{project.path_with_namespace}:#{merge_request.target_branch}" }

      it { is_expected.to eq([source_title, target_title]) }
    end
  end
end
