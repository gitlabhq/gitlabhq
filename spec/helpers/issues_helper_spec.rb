require "spec_helper"

describe IssuesHelper do
  let(:project) { create :project }
  let(:issue) { create :issue, project: project }
  let(:ext_project) { create :redmine_project }

  describe :title_for_issue do
    it "should return issue title if used internal tracker" do
      @project = project
      title_for_issue(issue.id).should eq issue.title
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
      url_for_issue(issue.id).should match(int_expected)
    end

    it "should return path to external tracker" do
      @project = ext_project

      url_for_issue(issue_id).should match(ext_expected)
    end

    it "should return empty string if project nil" do
      @project = nil

      url_for_issue(issue.id).should eq ""
    end
  end
end
