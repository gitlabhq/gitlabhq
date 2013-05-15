require 'spec_helper'

describe Issues::BulkUpdateContext do

  describe :close_issue do

    before do
      @user = create :user
      opts = {
        name: "GitLab"
      }
      @project = create_project(@user, opts)
      @issues = 5.times.collect do
        create(:issue, project: @project)
      end
      @params = { 
        update: {
          status: 'closed',
          issues_ids: @issues.map(&:id)
        }
      }

    end

    it "close issues" do
      Issues::BulkUpdateContext.new(@project, @user, @params).execute
      @project.issues.opened.should be_empty
      @project.issues.closed.should_not be_empty
    end

    it "return success" do
      result = Issues::BulkUpdateContext.new(@project, @user, @params).execute
      result[:success].should be_true
      result[:count].should == @issues.count
    end

  end

  describe :reopen_issues do

    before do
      @user = create :user
      opts = {
        name: "GitLab"
      }
      @project = create_project(@user, opts)
      @issues = 5.times.collect do
        create(:closed_issue, project: @project)
      end
      @params = { 
        update: {
          status: 'reopen',
          issues_ids: @issues.map(&:id)
        }
      }

    end

    it "reopen issues" do
      Issues::BulkUpdateContext.new(@project, @user, @params).execute
      @project.issues.closed.should be_empty
      @project.issues.opened.should_not be_empty
    end

    it "return success" do
      result = Issues::BulkUpdateContext.new(@project, @user, @params).execute
      result[:success].should be_true
      result[:count].should == @issues.count
    end

  end

  def create_project(user, opts)
    Projects::CreateContext.new(user, opts).execute
  end
end

