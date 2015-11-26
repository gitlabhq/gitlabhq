require "spec_helper"

describe IssuesHelper do
  let(:project) { create :project }
  let(:issue) { create :issue, project: project }
  let(:ext_project) { create :redmine_project }

  describe "url_for_project_issues" do
    let(:project_url) { ext_project.external_issue_tracker.project_url }
    let(:ext_expected) do
      project_url.gsub(':project_id', ext_project.id.to_s)
                 .gsub(':issues_tracker_id', ext_project.issues_tracker_id.to_s)
    end
    let(:int_expected) { polymorphic_path([@project.namespace, project]) }

    it "should return internal path if used internal tracker" do
      @project = project
      expect(url_for_project_issues).to match(int_expected)
    end

    it "should return path to external tracker" do
      @project = ext_project

      expect(url_for_project_issues).to match(ext_expected)
    end

    it "should return empty string if project nil" do
      @project = nil

      expect(url_for_project_issues).to eq ""
    end

    describe "when external tracker was enabled and then config removed" do
      before do
        @project = ext_project
        allow(Gitlab.config).to receive(:issues_tracker).and_return(nil)
      end

      it "should return path to external tracker" do
        expect(url_for_project_issues).to match(ext_expected)
      end
    end
  end

  describe "url_for_issue" do
    let(:issues_url) { ext_project.external_issue_tracker.issues_url}
    let(:ext_expected) do
      issues_url.gsub(':id', issue.iid.to_s)
        .gsub(':project_id', ext_project.id.to_s)
        .gsub(':issues_tracker_id', ext_project.issues_tracker_id.to_s)
    end
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

  describe '#url_for_new_issue' do
    let(:issues_url) { ext_project.external_issue_tracker.new_issue_url }
    let(:ext_expected) do
      issues_url.gsub(':project_id', ext_project.id.to_s)
        .gsub(':issues_tracker_id', ext_project.issues_tracker_id.to_s)
    end
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

  describe "#merge_requests_sentence" do
    subject { merge_requests_sentence(merge_requests)}
    let(:merge_requests) do
      [ build(:merge_request, iid: 1), build(:merge_request, iid: 2),
        build(:merge_request, iid: 3)]
    end

    it { is_expected.to eq("!1, !2, or !3") }
  end

  describe "#url_to_emoji" do
    it "returns url" do
      expect(url_to_emoji("smile")).to include("emoji/1F604.png")
    end
  end

  describe "#emoji_list" do
    it "returns url" do
      expect(emoji_list).to be_kind_of(Array)
    end
  end

  describe "#note_active_class" do
    before do
      @note = create :note
      @note1 = create :note
    end

    it "returns empty string for unauthenticated user" do
      expect(note_active_class(Note.all, nil)).to eq("")
    end

    it "returns active string for author" do
      expect(note_active_class(Note.all, @note.author)).to eq("active")
    end
  end
end
