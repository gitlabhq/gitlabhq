require "spec_helper"

describe GitlabMarkdownHelper do
  before do
    @project = Project.find_by_path("gitlabhq") || Factory(:project)
    @commit = @project.repo.commits.first.parents.first
    @commit = CommitDecorator.decorate(Commit.new(@commit))
    @other_project = Factory :project, path: "OtherPath", code: "OtherCode"
    @fake_user = Factory :user, name: "fred"
  end

  describe "#gfm" do
    it "should return text if @project is not set" do
      @project = nil

      gfm("foo").should == "foo"
    end

    describe "referencing a commit" do
      it "should link using a full id" do
        gfm("Reverts changes from #{@commit.id}").should == "Reverts changes from #{link_to @commit.id, project_commit_path(@project, id: @commit.id), title: "Commit: #{@commit.author_name} - #{@commit.title}", class: "gfm gfm-commit "}"
      end

      it "should link using a short id" do
        gfm("Backported from #{@commit.id[0, 6]}").should == "Backported from #{link_to @commit.id[0, 6], project_commit_path(@project, id: @commit.id), title: "Commit: #{@commit.author_name} - #{@commit.title}", class: "gfm gfm-commit "}"
      end

      it "should link with adjecent text" do
        gfm("Reverted (see #{@commit.id})").should == "Reverted (see #{link_to @commit.id, project_commit_path(@project, id: @commit.id), title: "Commit: #{@commit.author_name} - #{@commit.title}", class: "gfm gfm-commit "})"
      end

      it "should not link with an invalid id" do
        gfm("What happened in 12345678?").should == "What happened in 12345678?"
      end
    end

    describe "referencing a team member" do
      it "should link using a simple name" do
        user = Factory :user, name: "barry"
        @project.users << user
        member = @project.users_projects.where(user_id: user).first

        gfm("@#{user.name} you are right").should == "#{link_to "@#{user.name}", project_team_member_path(@project, member), class: "gfm gfm-team_member "} you are right"
      end

      it "should link using a name with dots" do
        user = Factory :user, name: "alphA.Beta"
        @project.users << user
        member = @project.users_projects.where(user_id: user).first

        gfm("@#{user.name} you are right").should == "#{link_to "@#{user.name}", project_team_member_path(@project, member), class: "gfm gfm-team_member "} you are right"
      end

      it "should link using name with underscores" do
        user = Factory :user, name: "ping_pong_king"
        @project.users << user
        member = @project.users_projects.where(user_id: user).first

        gfm("@#{user.name} you are right").should == "#{link_to "@#{user.name}", project_team_member_path(@project, member), class: "gfm gfm-team_member "} you are right"
      end

      it "should link with adjecent text" do
        user = Factory.create(:user, name: "ace")
        @project.users << user
        member = @project.users_projects.where(user_id: user).first

        gfm("Mail the Admin (@#{user.name})").should == "Mail the Admin (#{link_to "@#{user.name}", project_team_member_path(@project, member), class: "gfm gfm-team_member "})"
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
        @issue = Factory :issue, assignee: @fake_user, author: @fake_user, project: @project
        @invalid_issue = Factory :issue, assignee: @fake_user, author: @fake_user, project: @other_project
      end

      it "should link using a correct id" do
        gfm("Fixes ##{@issue.id}").should == "Fixes #{link_to "##{@issue.id}", project_issue_path(@project, @issue), title: "Issue: #{@issue.title}", class: "gfm gfm-issue "}"
      end

      it "should link with adjecent text" do
        gfm("This has already been discussed (see ##{@issue.id})").should == "This has already been discussed (see #{link_to "##{@issue.id}", project_issue_path(@project, @issue), title: "Issue: #{@issue.title}", class: "gfm gfm-issue "})"
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
        @merge_request = Factory :merge_request, assignee: @fake_user, author: @fake_user, project: @project
        @invalid_merge_request = Factory :merge_request, assignee: @fake_user, author: @fake_user, project: @other_project
      end

      it "should link using a correct id" do
        gfm("Fixed in !#{@merge_request.id}").should == "Fixed in #{link_to "!#{@merge_request.id}", project_merge_request_path(@project, @merge_request), title: "Merge Request: #{@merge_request.title}", class: "gfm gfm-merge_request "}"
      end

      it "should link with adjecent text" do
        gfm("This has been fixed already (see !#{@merge_request.id})").should == "This has been fixed already (see #{link_to "!#{@merge_request.id}", project_merge_request_path(@project, @merge_request), title: "Merge Request: #{@merge_request.title}", class: "gfm gfm-merge_request "})"
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
                                  title: "Render asset to string",
                                  author: @fake_user,
                                  project: @project)
      end

      it "should link using a correct id" do
        gfm("Check out $#{@snippet.id}").should == "Check out #{link_to "$#{@snippet.id}", project_snippet_path(@project, @snippet), title: "Snippet: #{@snippet.title}", class: "gfm gfm-snippet "}"
      end

      it "should link with adjecent text" do
        gfm("I have created a snippet for that ($#{@snippet.id})").should == "I have created a snippet for that (#{link_to "$#{@snippet.id}", project_snippet_path(@project, @snippet), title: "Snippet: #{@snippet.title}", class: "gfm gfm-snippet "})"
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
      member = @project.users_projects.where(user_id: user).first

      gfm("Let @#{user.name} fix the *mess* in #{@commit.id}").should == "Let #{link_to "@#{user.name}", project_team_member_path(@project, member), class: "gfm gfm-team_member "} fix the *mess* in #{link_to @commit.id, project_commit_path(@project, id: @commit.id), title: "Commit: #{@commit.author_name} - #{@commit.title}", class: "gfm gfm-commit "}"
    end

    it "should not trip over other stuff", focus: true do
      gfm("_Please_ *stop* 'helping' and all the other b*$#%' you do.").should == "_Please_ *stop* 'helping' and all the other b*$#%' you do."
    end

    it "should not touch HTML entities" do
      gfm("We&#39;ll accept good pull requests.").should == "We&#39;ll accept good pull requests."
    end

    it "should forward HTML options to links" do
      gfm("fixed in #{@commit.id}", class: "foo").should have_selector("a.foo")
    end
  end

  describe "#link_to_gfm" do
    let(:issue1) { Factory :issue, assignee: @fake_user, author: @fake_user, project: @project }
    let(:issue2) { Factory :issue, assignee: @fake_user, author: @fake_user, project: @project }

    it "should handle references nested in links with all the text" do
      link_to_gfm("This should finally fix ##{issue1.id} and ##{issue2.id} for real", project_commit_path(@project, id: @commit.id)).should == "#{link_to "This should finally fix ", project_commit_path(@project, id: @commit.id)}#{link_to "##{issue1.id}", project_issue_path(@project, issue1), title: "Issue: #{issue1.title}", class: "gfm gfm-issue "}#{link_to " and ", project_commit_path(@project, id: @commit.id)}#{link_to "##{issue2.id}", project_issue_path(@project, issue2), title: "Issue: #{issue2.title}", class: "gfm gfm-issue "}#{link_to " for real", project_commit_path(@project, id: @commit.id)}"
    end

    it "should forward HTML options" do
      link_to_gfm("This should finally fix ##{issue1.id} for real", project_commit_path(@project, id: @commit.id), class: "foo").should have_selector(".foo")
    end
  end

  describe "#markdown" do
    before do
      @issue = Factory :issue, assignee: @fake_user, author: @fake_user, project: @project
      @merge_request = Factory :merge_request, assignee: @fake_user, author: @fake_user, project: @project
      @note = Factory.create(:note,
                              note: "Screenshot of the new feature",
                              project: @project,
                              noteable_id: @commit.id,
                              noteable_type: "Commit",
                              attachment: "screenshot123.jpg")
      @snippet = Factory.create(:snippet,
                                title: "Render asset to string",
                                author: @fake_user,
                                project: @project)

      @other_user = Factory :user, name: "bill"
      @project.users << @other_user
      @member = @project.users_projects.where(user_id: @other_user).first
    end

    it "should handle references in paragraphs" do
      markdown("\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. #{@commit.id} Nam pulvinar sapien eget odio adipiscing at faucibus orci vestibulum.\n").should == "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. #{link_to @commit.id, project_commit_path(@project, id: @commit.id), title: "Commit: #{@commit.author_name} - #{@commit.title}", class: "gfm gfm-commit "} Nam pulvinar sapien eget odio adipiscing at faucibus orci vestibulum.</p>\n"
    end

    it "should handle references in headers" do
      markdown("\n# Working around ##{@issue.id} for now\n## Apply !#{@merge_request.id}").should == "<h1 id=\"toc_0\">Working around #{link_to "##{@issue.id}", project_issue_path(@project, @issue), title: "Issue: #{@issue.title}", class: "gfm gfm-issue "} for now</h1>\n\n<h2 id=\"toc_1\">Apply #{link_to "!#{@merge_request.id}", project_merge_request_path(@project, @merge_request), title: "Merge Request: #{@merge_request.title}", class: "gfm gfm-merge_request "}</h2>\n"
    end

    it "should handle references in lists" do
      markdown("\n* dark: ##{@issue.id}\n* light by @#{@other_user.name}\n").should == "<ul>\n<li>dark: #{link_to "##{@issue.id}", project_issue_path(@project, @issue), title: "Issue: #{@issue.title}", class: "gfm gfm-issue "}</li>\n<li>light by #{link_to "@#{@other_user.name}", project_team_member_path(@project, @member), class: "gfm gfm-team_member "}</li>\n</ul>\n"
    end

    it "should handle references in <em>" do
      markdown("Apply _!#{@merge_request.id}_ ASAP").should == "<p>Apply <em>#{link_to "!#{@merge_request.id}", project_merge_request_path(@project, @merge_request), title: "Merge Request: #{@merge_request.title}", class: "gfm gfm-merge_request "}</em> ASAP</p>\n"
    end

    it "should leave code blocks untouched" do
      markdown("\n    some code from $#{@snippet.id}\n    here too\n").should == "<div class=\"highlight\"><pre><span class=\"n\">some</span> <span class=\"n\">code</span> <span class=\"n\">from</span> $#{@snippet.id}\n<span class=\"n\">here</span> <span class=\"n\">too</span>\n</pre>\n</div>\n"

      markdown("\n```\nsome code from $#{@snippet.id}\nhere too\n```\n").should == "<div class=\"highlight\"><pre><span class=\"n\">some</span> <span class=\"n\">code</span> <span class=\"n\">from</span> $#{@snippet.id}\n<span class=\"n\">here</span> <span class=\"n\">too</span>\n</pre>\n</div>\n"
    end

    it "should leave inline code untouched" do
      markdown("\nDon't use `$#{@snippet.id}` here.\n").should == "<p>Don&#39;t use <code>$#{@snippet.id}</code> here.</p>\n"
    end
  end
end
