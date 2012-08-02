require "spec_helper"

describe ApplicationHelper do
  before do
    @project = Project.find_by_path("gitlabhq") || Factory(:project)
    @commit = @project.repo.commits.first.parents.first
    @commit = CommitDecorator.decorate(Commit.new(@commit))
    @other_project = Factory :project, :path => "OtherPath", :code => "OtherCode"
    @fake_user = Factory :user, :name => "fred"
  end

  describe "#gfm" do
    describe "referencing a commit" do
      it "should link using a full id" do
        gfm("Reverts changes from #{@commit.id}").should == "Reverts changes from #{link_to @commit.id, project_commit_path(@project, :id => @commit.id), :title => "Commit: #{@commit.author_name} - #{@commit.title}", :class => "gfm gfm-commit "}"
      end

      it "should link using a short id" do
        gfm("Backported from #{@commit.id[0, 6]}").should == "Backported from #{link_to @commit.id[0, 6], project_commit_path(@project, :id => @commit.id), :title => "Commit: #{@commit.author_name} - #{@commit.title}", :class => "gfm gfm-commit "}"
      end

      it "should link with adjecent text" do
        gfm("Reverted (see #{@commit.id})").should == "Reverted (see #{link_to @commit.id, project_commit_path(@project, :id => @commit.id), :title => "Commit: #{@commit.author_name} - #{@commit.title}", :class => "gfm gfm-commit "})"
      end

      it "should not link with an invalid id" do
        gfm("What happened in 12345678?").should == "What happened in 12345678?"
      end
    end

    describe "referencing a team member" do
      it "should link using a simple name" do
        user = Factory :user, name: "barry"
        @project.users << user
        member = @project.users_projects.where(:user_id => user).first

        gfm("@#{user.name} you are right").should == "#{link_to "@#{user.name}", project_team_member_path(@project, member), :class => "gfm gfm-team_member "} you are right"
      end

      it "should link using a name with dots" do
        user = Factory :user, name: "alphA.Beta"
        @project.users << user
        member = @project.users_projects.where(:user_id => user).first

        gfm("@#{user.name} you are right").should == "#{link_to "@#{user.name}", project_team_member_path(@project, member), :class => "gfm gfm-team_member "} you are right"
      end

      it "should link using name with underscores" do
        user = Factory :user, name: "ping_pong_king"
        @project.users << user
        member = @project.users_projects.where(:user_id => user).first

        gfm("@#{user.name} you are right").should == "#{link_to "@#{user.name}", project_team_member_path(@project, member), :class => "gfm gfm-team_member "} you are right"
      end

      it "should link with adjecent text" do
        user = Factory.create(:user, :name => "ace")
        @project.users << user
        member = @project.users_projects.where(:user_id => user).first

        gfm("Mail the Admin (@#{user.name})").should == "Mail the Admin (#{link_to "@#{user.name}", project_team_member_path(@project, member), :class => "gfm gfm-team_member "})"
      end

      it "should add styles" do
        user = Factory :user, name: "barry"
        @project.users << user
        gfm("@#{user.name} you are right").should have_selector(".gfm.gfm-team_member")
      end

      it "should not link using a bogus name" do
        gfm("What hapened to @foo?").should == "What hapened to @foo?"
      end
    end

    describe "referencing an issue" do
      before do
        @issue = Factory :issue, :assignee => @fake_user, :author => @fake_user, :project => @project
        @invalid_issue = Factory :issue, :assignee => @fake_user, :author => @fake_user, :project => @other_project
      end

      it "should link using a correct id" do
        gfm("Fixes ##{@issue.id}").should == "Fixes #{link_to "##{@issue.id}", project_issue_path(@project, @issue), :title => "Issue: #{@issue.title}", :class => "gfm gfm-issue "}"
      end

      it "should link with adjecent text" do
        gfm("This has already been discussed (see ##{@issue.id})").should == "This has already been discussed (see #{link_to "##{@issue.id}", project_issue_path(@project, @issue), :title => "Issue: #{@issue.title}", :class => "gfm gfm-issue "})"
      end

      it "should add styles" do
        gfm("Fixes ##{@issue.id}").should have_selector(".gfm.gfm-issue")
      end

      it "should not link using an invalid id" do
        gfm("##{@invalid_issue.id} has been marked duplicate of this").should == "##{@invalid_issue.id} has been marked duplicate of this"
      end
    end

    describe "referencing a merge request" do
      before do
        @merge_request = Factory :merge_request, :assignee => @fake_user, :author => @fake_user, :project => @project
        @invalid_merge_request = Factory :merge_request, :assignee => @fake_user, :author => @fake_user, :project => @other_project
      end

      it "should link using a correct id" do
        gfm("Fixed in !#{@merge_request.id}").should == "Fixed in #{link_to "!#{@merge_request.id}", project_merge_request_path(@project, @merge_request), :title => "Merge Request: #{@merge_request.title}", :class => "gfm gfm-merge_request "}"
      end

      it "should link with adjecent text" do
        gfm("This has been fixed already (see !#{@merge_request.id})").should == "This has been fixed already (see #{link_to "!#{@merge_request.id}", project_merge_request_path(@project, @merge_request), :title => "Merge Request: #{@merge_request.title}", :class => "gfm gfm-merge_request "})"
      end

      it "should add styles" do
        gfm("Fixed in !#{@merge_request.id}").should have_selector(".gfm.gfm-merge_request")
      end

      it "should not link using an invalid id" do
        gfm("!#{@invalid_merge_request.id} violates our coding guidelines")
      end
    end

    describe "referencing a snippet" do
      before do
        @snippet = Factory.create(:snippet,
                                  :title => "Render asset to string",
                                  :author => @fake_user,
                                  :project => @project)
      end

      it "should link using a correct id" do
        gfm("Check out $#{@snippet.id}").should == "Check out #{link_to "$#{@snippet.id}", project_snippet_path(@project, @snippet), :title => "Snippet: #{@snippet.title}", :class => "gfm gfm-snippet "}"
      end

      it "should link with adjecent text" do
        gfm("I have created a snippet for that ($#{@snippet.id})").should == "I have created a snippet for that (#{link_to "$#{@snippet.id}", project_snippet_path(@project, @snippet), :title => "Snippet: #{@snippet.title}", :class => "gfm gfm-snippet "})"
      end

      it "should add styles" do
        gfm("Check out $#{@snippet.id}").should have_selector(".gfm.gfm-snippet")
      end

      it "should not link using an invalid id" do
        gfm("Don't use $1234").should == "Don't use $1234"
      end
    end

    it "should link to multiple things" do
      user = Factory :user, name: "barry"
      @project.users << user
      member = @project.users_projects.where(:user_id => user).first

      gfm("Let @#{user.name} fix the *mess* in #{@commit.id}").should == "Let #{link_to "@#{user.name}", project_team_member_path(@project, member), :class => "gfm gfm-team_member "} fix the *mess* in #{link_to @commit.id, project_commit_path(@project, :id => @commit.id), :title => "Commit: #{@commit.author_name} - #{@commit.title}", :class => "gfm gfm-commit "}"
    end

    it "should not trip over other stuff", :focus => true do
      gfm("_Please_ *stop* 'helping' and all the other b*$#%' you do.").should == "_Please_ *stop* 'helping' and all the other b*$#%' you do."
    end

    it "should not touch HTML entities" do
      gfm("We&#39;ll accept good pull requests.").should == "We&#39;ll accept good pull requests."
    end

    it "should forward HTML options to links" do
      gfm("fixed in #{@commit.id}", :class => "foo").should have_selector("a.foo")
    end
  end
end
