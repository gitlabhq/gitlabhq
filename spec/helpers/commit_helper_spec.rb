require "spec_helper"
include Haml::Helpers

describe CommitsHelper do

  before do
    @project = Factory :project
    @other_project = Factory :project, :path => "OtherPath", :code => "OtherCode"
    @fake_user = Factory :user
    @valid_issue = Factory :issue, :assignee => @fake_user, :author => @fake_user, :project => @project
    @invalid_issue = Factory :issue, :assignee => @fake_user, :author => @fake_user, :project => @other_project
  end

  it "should provides return message untouched if no issue number present" do
    message = "Dummy message without issue number"

    commit_msg_with_link_to_issues(@project, message).should eql message
  end

  it "should returns message handled by preserve" do
    message = "My brand new
    Commit on multiple
    lines !"

    #\n are converted to &#x000A as specified in preserve_rspec
    expected = "My brand new&#x000A;    Commit on multiple&#x000A;    lines !"

    commit_msg_with_link_to_issues(@project, message).should eql expected
  end

  it "should returns empty string if message undefined" do
    commit_msg_with_link_to_issues(@project, nil).should eql ''
  end

  it "should returns link_to issue for one valid issue in message" do
    issue_id = @valid_issue.id
    message = "One commit message ##{issue_id}"
    expected = "One commit message <a href=\"/#{@project.code}/issues/#{issue_id}\">##{issue_id}</a>"

    commit_msg_with_link_to_issues(@project, message).should eql expected
  end

  it "should returns message untouched for one invalid issue in message" do
    issue_id = @invalid_issue.id
    message = "One commit message ##{issue_id}"

    commit_msg_with_link_to_issues(@project, message).should eql message
  end

  it "should handle multiple issue references in commit message" do
    issue_id = @valid_issue.id
    invalid_issue_id = @invalid_issue.id

    message = "One big commit message with a valid issue ##{issue_id} and an invalid one ##{invalid_issue_id}.
    We reference valid ##{issue_id} multiple times (##{issue_id}) as the invalid ##{invalid_issue_id} is also
    referenced another time (##{invalid_issue_id})"

    expected = "One big commit message with a valid issue <a href=\"/#{@project.code}/issues/#{issue_id}\">##{issue_id}</a>"+
        " and an invalid one ##{invalid_issue_id}.&#x000A;    "+
        "We reference valid <a href=\"/#{@project.code}/issues/#{issue_id}\">##{issue_id}</a> multiple times "+
        "(<a href=\"/#{@project.code}/issues/#{issue_id}\">##{issue_id}</a>) "+
        "as the invalid ##{invalid_issue_id} is also&#x000A;    referenced another time (##{invalid_issue_id})"

    commit_msg_with_link_to_issues(@project, message).should eql expected
  end

end