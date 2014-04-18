require "spec_helper"

describe IssuesHelper do
  let(:project) { create :project }
  let(:issue) { create :issue, project: project }
  let(:ext_project) { create :redmine_project }

  describe :title_for_issue do
    it "should return issue title if used internal tracker" do
      @project = project
      title_for_issue(issue.iid).should eq issue.title
    end

    it "should always return empty string if used external tracker" do
      @project = ext_project
      title_for_issue(rand(100)).should eq ""
    end

    it "should always return empty string if project nil" do
      @project = nil

      title_for_issue(rand(100)).should eq ""
    end
  end

  describe :url_for_project_issues do
    let(:project_url) { Gitlab.config.issues_tracker.redmine.project_url}
    let(:ext_expected) do
      project_url.gsub(':project_id', ext_project.id.to_s)
                 .gsub(':issues_tracker_id', ext_project.issues_tracker_id.to_s)
    end
    let(:int_expected) { polymorphic_path([project]) }

    it "should return internal path if used internal tracker" do
      @project = project
      url_for_project_issues.should match(int_expected)
    end

    it "should return path to external tracker" do
      @project = ext_project

      url_for_project_issues.should match(ext_expected)
    end

    it "should return empty string if project nil" do
      @project = nil

      url_for_project_issues.should eq ""
    end

    describe "when external tracker was enabled and then config removed" do
      before do
        @project = ext_project
        Gitlab.config.stub(:issues_tracker).and_return(nil)
      end

      it "should return path to internal tracker" do
        url_for_project_issues.should match(polymorphic_path([@project]))
      end
    end
  end

  describe :url_for_issue do
    let(:issue_id) { 3 }
    let(:issues_url) { Gitlab.config.issues_tracker.redmine.issues_url}
    let(:ext_expected) do
      issues_url.gsub(':id', issue_id.to_s)
        .gsub(':project_id', ext_project.id.to_s)
        .gsub(':issues_tracker_id', ext_project.issues_tracker_id.to_s)
    end
    let(:int_expected) { polymorphic_path([project, issue]) }

    it "should return internal path if used internal tracker" do
      @project = project
      url_for_issue(issue.iid).should match(int_expected)
    end

    it "should return path to external tracker" do
      @project = ext_project

      url_for_issue(issue_id).should match(ext_expected)
    end

    it "should return empty string if project nil" do
      @project = nil

      url_for_issue(issue.iid).should eq ""
    end

    describe "when external tracker was enabled and then config removed" do
      before do
        @project = ext_project
        Gitlab.config.stub(:issues_tracker).and_return(nil)
      end

      it "should return internal path" do
        url_for_issue(issue.iid).should match(polymorphic_path([@project, issue]))
      end
    end
  end

  describe :url_for_new_issue do
    let(:issues_url) { Gitlab.config.issues_tracker.redmine.new_issue_url}
    let(:ext_expected) do
      issues_url.gsub(':project_id', ext_project.id.to_s)
        .gsub(':issues_tracker_id', ext_project.issues_tracker_id.to_s)
    end
    let(:int_expected) { new_project_issue_path(project) }

    it "should return internal path if used internal tracker" do
      @project = project
      url_for_new_issue.should match(int_expected)
    end

    it "should return path to external tracker" do
      @project = ext_project

      url_for_new_issue.should match(ext_expected)
    end

    it "should return empty string if project nil" do
      @project = nil

      url_for_new_issue.should eq ""
    end

    describe "when external tracker was enabled and then config removed" do
      before do
        @project = ext_project
        Gitlab.config.stub(:issues_tracker).and_return(nil)
      end

      it "should return internal path" do
        url_for_new_issue.should match(new_project_issue_path(@project))
      end
    end
  end

end
