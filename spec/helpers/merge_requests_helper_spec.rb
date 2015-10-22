require 'spec_helper'

describe MergeRequestsHelper do
  describe "#issues_sentence" do
    subject { issues_sentence(issues) }
    let(:issues) do
      [build(:issue, iid: 1), build(:issue, iid: 2), build(:issue, iid: 3)]
    end

    it { is_expected.to eq('#1, #2, and #3') }
  end

  describe "#format_mr_branch_names" do
    describe "within the same project" do
      let(:merge_request) { create(:merge_request) }
      subject { format_mr_branch_names(merge_request) }

      it { is_expected.to eq([merge_request.source_branch, merge_request.target_branch]) }
    end

    describe "within different projects" do
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
