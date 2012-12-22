require "spec_helper"

describe GitlabMarkdownHelper do
  let!(:project) { create(:project) }

  let(:user)          { create(:user, username: 'gfm') }
  let(:commit)        { CommitDecorator.decorate(project.commit) }
  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, project: project) }
  let(:snippet)       { create(:snippet, project: project) }
  let(:member)        { project.users_projects.where(user_id: user).first }

  before do
    # Helper expects a @project instance variable
    @project = project
  end

  describe "#gfm" do
    it "should return unaltered text if project is nil" do
      actual = "Testing references: ##{issue.id}"

      gfm(actual).should_not == actual

      @project = nil
      gfm(actual).should == actual
    end

    it "should not alter non-references" do
      actual = expected = "_Please_ *stop* 'helping' and all the other b*$#%' you do."
      gfm(actual).should == expected
    end

    it "should not touch HTML entities" do
      @project.issues.stub(:where).with(id: '39').and_return([issue])
      actual = expected = "We&#39;ll accept good pull requests."
      gfm(actual).should == expected
    end

    it "should forward HTML options to links" do
      gfm("Fixed in #{commit.id}", class: "foo").should have_selector("a.gfm.foo")
    end

    describe "referencing a commit" do
      let(:expected) { project_commit_path(project, commit) }

      it "should link using a full id" do
        actual = "Reverts #{commit.id}"
        gfm(actual).should match(expected)
      end

      it "should link using a short id" do
        actual = "Backported from #{commit.short_id(6)}"
        gfm(actual).should match(expected)
      end

      it "should link with adjacent text" do
        actual = "Reverted (see #{commit.id})"
        gfm(actual).should match(expected)
      end

      it "should keep whitespace intact" do
        actual   = "Changes #{commit.id} dramatically"
        expected = /Changes <a.+>#{commit.id}<\/a> dramatically/
        gfm(actual).should match(expected)
      end

      it "should not link with an invalid id" do
        actual = expected = "What happened in #{commit.id.reverse}"
        gfm(actual).should == expected
      end

      it "should include a title attribute" do
        actual = "Reverts #{commit.id}"
        gfm(actual).should match(/title="#{commit.link_title}"/)
      end

      it "should include standard gfm classes" do
        actual = "Reverts #{commit.id}"
        gfm(actual).should match(/class="\s?gfm gfm-commit\s?"/)
      end
    end

    describe "referencing a team member" do
      let(:actual)   { "@#{user.username} you are right." }
      let(:expected) { project_team_member_path(project, member) }

      before do
        project.add_access(user, :admin)
      end

      it "should link using a simple name" do
        gfm(actual).should match(expected)
      end

      it "should link using a name with dots" do
        user.update_attributes(name: "alphA.Beta")
        gfm(actual).should match(expected)
      end

      it "should link using name with underscores" do
        user.update_attributes(name: "ping_pong_king")
        gfm(actual).should match(expected)
      end

      it "should link with adjacent text" do
        actual = "Mail the admin (@#{user.username})"
        gfm(actual).should match(expected)
      end

      it "should keep whitespace intact" do
        actual   = "Yes, @#{user.username} is right."
        expected = /Yes, <a.+>@#{user.username}<\/a> is right/
        gfm(actual).should match(expected)
      end

      it "should not link with an invalid id" do
        actual = expected = "@#{user.username.reverse} you are right."
        gfm(actual).should == expected
      end

      it "should include standard gfm classes" do
        gfm(actual).should match(/class="\s?gfm gfm-team_member\s?"/)
      end
    end

    # Shared examples for referencing an object
    #
    # Expects the following attributes to be available in the example group:
    #
    # - object    - The object itself
    # - reference - The object reference string (e.g., #1234, $1234, !1234)
    #
    # Currently limited to Snippets, Issues and MergeRequests
    shared_examples 'referenced object' do
      let(:actual)   { "Reference to #{reference}" }
      let(:expected) { polymorphic_path([project, object]) }

      it "should link using a valid id" do
        gfm(actual).should match(expected)
      end

      it "should link with adjacent text" do
        # Wrap the reference in parenthesis
        gfm(actual.gsub(reference, "(#{reference})")).should match(expected)

        # Append some text to the end of the reference
        gfm(actual.gsub(reference, "#{reference}, right?")).should match(expected)
      end

      it "should keep whitespace intact" do
        actual   = "Referenced #{reference} already."
        expected = /Referenced <a.+>[^\s]+<\/a> already/
        gfm(actual).should match(expected)
      end

      it "should not link with an invalid id" do
        # Modify the reference string so it's still parsed, but is invalid
        reference.gsub!(/^(.)(\d+)$/, '\1' + ('\2' * 2))
        gfm(actual).should == actual
      end

      it "should include a title attribute" do
        title = "#{object.class.to_s.titlecase}: #{object.title}"
        gfm(actual).should match(/title="#{title}"/)
      end

      it "should include standard gfm classes" do
        css = object.class.to_s.underscore
        gfm(actual).should match(/class="\s?gfm gfm-#{css}\s?"/)
      end
    end

    describe "referencing an issue" do
      let(:object)    { issue }
      let(:reference) { "##{issue.id}" }

      include_examples 'referenced object'
    end

    describe "referencing a merge request" do
      let(:object)    { merge_request }
      let(:reference) { "!#{merge_request.id}" }

      include_examples 'referenced object'
    end

    describe "referencing a snippet" do
      let(:object)    { snippet }
      let(:reference) { "$#{snippet.id}" }

      include_examples 'referenced object'
    end

    describe "referencing multiple objects" do
      let(:actual) { "!#{merge_request.id} -> #{commit.id} -> ##{issue.id}" }

      it "should link to the merge request" do
        expected = project_merge_request_path(project, merge_request)
        gfm(actual).should match(expected)
      end

      it "should link to the commit" do
        expected = project_commit_path(project, commit)
        gfm(actual).should match(expected)
      end

      it "should link to the issue" do
        expected = project_issue_path(project, issue)
        gfm(actual).should match(expected)
      end
    end

    describe "emoji" do
      it "matches at the start of a string" do
        gfm(":+1:").should match(/<img/)
      end

      it "matches at the end of a string" do
        gfm("This gets a :-1:").should match(/<img/)
      end

      it "matches with adjacent text" do
        gfm("+1 (:+1:)").should match(/<img/)
      end

      it "has a title attribute" do
        gfm(":-1:").should match(/title=":-1:"/)
      end

      it "has an alt attribute" do
        gfm(":-1:").should match(/alt=":-1:"/)
      end

      it "has an emoji class" do
        gfm(":+1:").should match('class="emoji"')
      end

      it "sets height and width" do
        actual = gfm(":+1:")
        actual.should match(/width="20"/)
        actual.should match(/height="20"/)
      end

      it "keeps whitespace intact" do
        gfm("This deserves a :+1: big time.").should match(/deserves a <img.+\/> big time/)
      end

      it "ignores invalid emoji" do
        gfm(":invalid-emoji:").should_not match(/<img/)
      end

      it "should work independet of reference links (i.e. without @project being set)" do
        @project = nil
        gfm(":+1:").should match(/<img/)
      end
    end
  end

  describe "#link_to_gfm" do
    let(:commit_path) { project_commit_path(project, commit) }
    let(:issues)      { create_list(:issue, 2, project: project) }

    it "should handle references nested in links with all the text" do
      actual = link_to_gfm("This should finally fix ##{issues[0].id} and ##{issues[1].id} for real", commit_path)

      # Break the result into groups of links with their content, without
      # closing tags
      groups = actual.split("</a>")

      # Leading commit link
      groups[0].should match(/href="#{commit_path}"/)
      groups[0].should match(/This should finally fix $/)

      # First issue link
      groups[1].should match(/href="#{project_issue_path(project, issues[0])}"/)
      groups[1].should match(/##{issues[0].id}$/)

      # Internal commit link
      groups[2].should match(/href="#{commit_path}"/)
      groups[2].should match(/ and /)

      # Second issue link
      groups[3].should match(/href="#{project_issue_path(project, issues[1])}"/)
      groups[3].should match(/##{issues[1].id}$/)

      # Trailing commit link
      groups[4].should match(/href="#{commit_path}"/)
      groups[4].should match(/ for real$/)
    end

    it "should forward HTML options" do
      actual = link_to_gfm("Fixed in #{commit.id}", commit_path, class: 'foo')
      actual.should have_selector 'a.gfm.gfm-commit.foo'
    end

    it "escapes HTML passed in as the body" do
      actual = "This is a <h1>test</h1> - see ##{issues[0].id}"
      link_to_gfm(actual, commit_path).should match('&lt;h1&gt;test&lt;/h1&gt;')
    end
  end

  describe "#markdown" do
    it "should handle references in paragraphs" do
      actual = "\n\nLorem ipsum dolor sit amet. #{commit.id} Nam pulvinar sapien eget.\n"
      expected = project_commit_path(project, commit)
      markdown(actual).should match(expected)
    end

    it "should handle references in headers" do
      actual = "\n# Working around ##{issue.id}\n## Apply !#{merge_request.id}"

      markdown(actual).should match(%r{<h1[^<]*>Working around <a.+>##{issue.id}</a></h1>})
      markdown(actual).should match(%r{<h2[^<]*>Apply <a.+>!#{merge_request.id}</a></h2>})
    end

    it "should handle references in lists" do
      project.add_access(user, :admin)

      actual = "\n* dark: ##{issue.id}\n* light by @#{member.user.username}"

      markdown(actual).should match(%r{<li>dark: <a.+>##{issue.id}</a></li>})
      markdown(actual).should match(%r{<li>light by <a.+>@#{member.user.username}</a></li>})
    end

    it "should handle references in <em>" do
      actual = "Apply _!#{merge_request.id}_ ASAP"

      markdown(actual).should match(%r{Apply <em><a.+>!#{merge_request.id}</a></em>})
    end

    it "should leave code blocks untouched" do
      helper.stub(:user_color_scheme_class).and_return(:white)

      helper.markdown("\n    some code from $#{snippet.id}\n    here too\n").should include("<div class=\"white\"><div class=\"highlight\"><pre><span class=\"n\">some</span> <span class=\"n\">code</span> <span class=\"n\">from</span> $#{snippet.id}\n<span class=\"n\">here</span> <span class=\"n\">too</span>\n</pre></div></div>")

      helper.markdown("\n```\nsome code from $#{snippet.id}\nhere too\n```\n").should include("<div class=\"white\"><div class=\"highlight\"><pre><span class=\"n\">some</span> <span class=\"n\">code</span> <span class=\"n\">from</span> $#{snippet.id}\n<span class=\"n\">here</span> <span class=\"n\">too</span>\n</pre></div></div>")
    end

    it "should leave inline code untouched" do
      markdown("\nDon't use `$#{snippet.id}` here.\n").should == "<p>Don&#39;t use <code>$#{snippet.id}</code> here.</p>\n"
    end
  end
end
