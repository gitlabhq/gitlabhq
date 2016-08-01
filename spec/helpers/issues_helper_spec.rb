require "spec_helper"

describe IssuesHelper do
  let(:project) { create :project }
  let(:issue) { create :issue, project: project }
  let(:ext_project) { create :redmine_project }

  describe "url_for_issue" do
    let(:issues_url) { ext_project.external_issue_tracker.issues_url}
    let(:ext_expected) { issues_url.gsub(':id', issue.iid.to_s).gsub(':project_id', ext_project.id.to_s) }
    let(:int_expected) { polymorphic_path([@project.namespace, project, issue]) }

    it "should return internal path if used internal tracker" do
      @project = project
      expect(url_for_issue(issue.iid)).to match(int_expected)
    end

    it "should return path to external tracker" do
      @project = ext_project

      expect(url_for_issue(issue.iid)).to match(ext_expected)
    end

    it "should return empty string if project nil" do
      @project = nil

      expect(url_for_issue(issue.iid)).to eq ""
    end

    it 'returns an empty string if issue_url is invalid' do
      expect(project).to receive_message_chain('issues_tracker.issue_url') { 'javascript:alert("foo");' }

      expect(url_for_issue(issue.iid, project)).to eq ''
    end

    it 'returns an empty string if issue_path is invalid' do
      expect(project).to receive_message_chain('issues_tracker.issue_path') { 'javascript:alert("foo");' }

      expect(url_for_issue(issue.iid, project, only_path: true)).to eq ''
    end

    describe "when external tracker was enabled and then config removed" do
      before do
        @project = ext_project
        allow(Gitlab.config).to receive(:issues_tracker).and_return(nil)
      end

      it "should return external path" do
        expect(url_for_issue(issue.iid)).to match(ext_expected)
      end
    end
  end

  describe 'url_for_new_issue' do
    let(:issues_url) { ext_project.external_issue_tracker.new_issue_url }
    let(:ext_expected) { issues_url.gsub(':project_id', ext_project.id.to_s) }
    let(:int_expected) { new_namespace_project_issue_path(project.namespace, project) }

    it "should return internal path if used internal tracker" do
      @project = project
      expect(url_for_new_issue).to match(int_expected)
    end

    it "should return path to external tracker" do
      @project = ext_project

      expect(url_for_new_issue).to match(ext_expected)
    end

    it "should return empty string if project nil" do
      @project = nil

      expect(url_for_new_issue).to eq ""
    end

    it 'returns an empty string if issue_url is invalid' do
      expect(project).to receive_message_chain('issues_tracker.new_issue_url') { 'javascript:alert("foo");' }

      expect(url_for_new_issue(project)).to eq ''
    end

    it 'returns an empty string if issue_path is invalid' do
      expect(project).to receive_message_chain('issues_tracker.new_issue_path') { 'javascript:alert("foo");' }

      expect(url_for_new_issue(project, only_path: true)).to eq ''
    end

    describe "when external tracker was enabled and then config removed" do
      before do
        @project = ext_project
        allow(Gitlab.config).to receive(:issues_tracker).and_return(nil)
      end

      it "should return internal path" do
        expect(url_for_new_issue).to match(ext_expected)
      end
    end
  end

  describe "merge_requests_sentence" do
    subject { merge_requests_sentence(merge_requests)}
    let(:merge_requests) do
      [ build(:merge_request, iid: 1), build(:merge_request, iid: 2),
        build(:merge_request, iid: 3)]
    end

    it { is_expected.to eq("!1, !2, or !3") }
  end

  describe '#award_active_class' do
    let!(:upvote) { create(:award_emoji) }

    it "returns empty string for unauthenticated user" do
      expect(award_active_class(AwardEmoji.all, nil)).to eq("")
    end

    it "returns active string for author" do
      expect(award_active_class(AwardEmoji.all, upvote.user)).to eq("active")
    end
  end

  describe "awards_sort" do
    it "sorts a hash so thumbsup and thumbsdown are always on top" do
      data = { "thumbsdown" => "some value", "lifter" => "some value", "thumbsup" => "some value" }
      expect(awards_sort(data).keys).to eq(["thumbsup", "thumbsdown", "lifter"])
    end
  end

  describe "milestone_options" do
    it "gets closed milestone from current issue" do
      closed_milestone = create(:closed_milestone, project: project)
      milestone1       = create(:milestone, project: project)
      milestone2       = create(:milestone, project: project)
      issue.update_attributes(milestone_id: closed_milestone.id)

      options = milestone_options(issue)

      expect(options).to have_selector('option[selected]', text: closed_milestone.title)
      expect(options).to have_selector('option', text: milestone1.title)
      expect(options).to have_selector('option', text: milestone2.title)
    end
  end
end
