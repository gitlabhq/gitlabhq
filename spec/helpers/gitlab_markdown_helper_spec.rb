require 'spec_helper'

describe GitlabMarkdownHelper do
  include ApplicationHelper
  include IssuesHelper

  let!(:project) { create(:project) }
  let(:empty_project) { create(:empty_project) }

  let(:user)          { create(:user, username: 'gfm') }
  let(:commit)        { project.repository.commit }
  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:snippet)       { create(:project_snippet, project: project) }
  let(:member)        { project.project_members.where(user_id: user).first }

  def url_helper(image_name)
    File.join(root_url, 'assets', image_name)
  end

  before do
    # Helper expects a @project instance variable
    @project = project
    @ref = 'markdown'
    @repository = project.repository
    @request.host = Gitlab.config.gitlab.host
  end

  describe "#gfm" do
    it "should return unaltered text if project is nil" do
      actual = "Testing references: ##{issue.iid}"

      expect(gfm(actual)).not_to eq(actual)

      @project = nil
      expect(gfm(actual)).to eq(actual)
    end

    it "should not alter non-references" do
      actual = expected = "_Please_ *stop* 'helping' and all the other b*$#%' you do."
      expect(gfm(actual)).to eq(expected)
    end

    it "should not touch HTML entities" do
      allow(@project.issues).to receive(:where).
        with(id: '39').and_return([issue])
      actual = 'We&#39;ll accept good pull requests.'
      expect(gfm(actual)).to eq("We'll accept good pull requests.")
    end

    it "should forward HTML options to links" do
      expect(gfm("Fixed in #{commit.id}", @project, class: 'foo')).
          to have_selector('a.gfm.foo')
    end

    describe "referencing a commit" do
      let(:expected) { namespace_project_commit_path(project.namespace, project, commit) }

      it "should link using a full id" do
        actual = "Reverts #{commit.id}"
        expect(gfm(actual)).to match(expected)
      end

      it "should link using a short id" do
        actual = "Backported from #{commit.short_id}"
        expect(gfm(actual)).to match(expected)
      end

      it "should link with adjacent text" do
        actual = "Reverted (see #{commit.id})"
        expect(gfm(actual)).to match(expected)
      end

      it "should keep whitespace intact" do
        actual   = "Changes #{commit.id} dramatically"
        expected = /Changes <a.+>#{commit.id}<\/a> dramatically/
        expect(gfm(actual)).to match(expected)
      end

      it "should not link with an invalid id" do
        actual = expected = "What happened in #{commit.id.reverse}"
        expect(gfm(actual)).to eq(expected)
      end

      it "should include a title attribute" do
        actual = "Reverts #{commit.id}"
        expect(gfm(actual)).to match(/title="#{commit.link_title}"/)
      end

      it "should include standard gfm classes" do
        actual = "Reverts #{commit.id}"
        expect(gfm(actual)).to match(/class="\s?gfm gfm-commit\s?"/)
      end
    end

    describe "referencing a team member" do
      let(:actual)   { "@#{user.username} you are right." }
      let(:expected) { user_path(user) }

      before do
        project.team << [user, :master]
      end

      it "should link using a simple name" do
        expect(gfm(actual)).to match(expected)
      end

      it "should link using a name with dots" do
        user.update_attributes(name: "alphA.Beta")
        expect(gfm(actual)).to match(expected)
      end

      it "should link using name with underscores" do
        user.update_attributes(name: "ping_pong_king")
        expect(gfm(actual)).to match(expected)
      end

      it "should link with adjacent text" do
        actual = "Mail the admin (@#{user.username})"
        expect(gfm(actual)).to match(expected)
      end

      it "should keep whitespace intact" do
        actual   = "Yes, @#{user.username} is right."
        expected = /Yes, <a.+>@#{user.username}<\/a> is right/
        expect(gfm(actual)).to match(expected)
      end

      it "should not link with an invalid id" do
        actual = expected = "@#{user.username.reverse} you are right."
        expect(gfm(actual)).to eq(expected)
      end

      it "should include standard gfm classes" do
        expect(gfm(actual)).to match(/class="\s?gfm gfm-team_member\s?"/)
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
      let(:expected) { polymorphic_path([project.namespace, project, object]) }

      it "should link using a valid id" do
        expect(gfm(actual)).to match(expected)
      end

      it "should link with adjacent text" do
        # Wrap the reference in parenthesis
        expect(gfm(actual.gsub(reference, "(#{reference})"))).to match(expected)

        # Append some text to the end of the reference
        expect(gfm(actual.gsub(reference, "#{reference}, right?"))).
          to match(expected)
      end

      it "should keep whitespace intact" do
        actual   = "Referenced #{reference} already."
        expected = /Referenced <a.+>[^\s]+<\/a> already/
        expect(gfm(actual)).to match(expected)
      end

      it "should not link with an invalid id" do
        # Modify the reference string so it's still parsed, but is invalid
        reference.gsub!(/^(.)(\d+)$/, '\1' + ('\2' * 2))
        expect(gfm(actual)).to eq(actual)
      end

      it "should include a title attribute" do
        title = "#{object.class.to_s.titlecase}: #{object.title}"
        expect(gfm(actual)).to match(/title="#{title}"/)
      end

      it "should include standard gfm classes" do
        css = object.class.to_s.underscore
        expect(gfm(actual)).to match(/class="\s?gfm gfm-#{css}\s?"/)
      end
    end

    # Shared examples for referencing an object in a different project
    #
    # Expects the following attributes to be available in the example group:
    #
    # - object    - The object itself
    # - reference - The object reference string (e.g., #1234, $1234, !1234)
    # - other_project - The project that owns the target object
    #
    # Currently limited to Snippets, Issues and MergeRequests
    shared_examples 'cross-project referenced object' do
      let(:project_path) { @other_project.path_with_namespace }
      let(:full_reference) { "#{project_path}#{reference}" }
      let(:actual)   { "Reference to #{full_reference}" }
      let(:expected) do
        if object.is_a?(Commit)
          namespace_project_commit_path(@other_project.namespace, @other_project, object)
        else
          polymorphic_path([@other_project.namespace, @other_project, object])
        end
      end

      it 'should link using a valid id' do
        expect(gfm(actual)).to match(
          /#{expected}.*#{Regexp.escape(full_reference)}/
        )
      end

      it 'should link with adjacent text' do
        # Wrap the reference in parenthesis
        expect(gfm(actual.gsub(full_reference, "(#{full_reference})"))).to(
          match(expected)
        )

        # Append some text to the end of the reference
        expect(gfm(actual.gsub(full_reference, "#{full_reference}, right?"))).
          to(match(expected))
      end

      it 'should keep whitespace intact' do
        actual   = "Referenced #{full_reference} already."
        expected = /Referenced <a.+>[^\s]+<\/a> already/
        expect(gfm(actual)).to match(expected)
      end

      it 'should not link with an invalid id' do
        # Modify the reference string so it's still parsed, but is invalid
        if object.is_a?(Commit)
          reference.gsub!(/^(.).+$/, '\1' + '12345abcd')
        else
          reference.gsub!(/^(.)(\d+)$/, '\1' + ('\2' * 2))
        end
        expect(gfm(actual)).to eq(actual)
      end

      it 'should include a title attribute' do
        if object.is_a?(Commit)
          title = object.link_title
        else
          title = "#{object.class.to_s.titlecase}: #{object.title}"
        end
        expect(gfm(actual)).to match(/title="#{title}"/)
      end

      it 'should include standard gfm classes' do
        css = object.class.to_s.underscore
        expect(gfm(actual)).to match(/class="\s?gfm gfm-#{css}\s?"/)
      end
    end

    describe "referencing an issue" do
      let(:object)    { issue }
      let(:reference) { "##{issue.iid}" }

      include_examples 'referenced object'
    end

    context 'cross-repo references' do
      before(:all) do
        @other_project = create(:project, :public)
        @commit2 = @other_project.repository.commit
        @issue2 = create(:issue, project: @other_project)
        @merge_request2 = create(:merge_request,
                                 source_project: @other_project,
                                 target_project: @other_project)
      end

      describe 'referencing an issue in another project' do
        let(:object)    { @issue2 }
        let(:reference) { "##{@issue2.iid}" }

        include_examples 'cross-project referenced object'
      end

      describe 'referencing an merge request in another project' do
        let(:object)    { @merge_request2 }
        let(:reference) { "!#{@merge_request2.iid}" }

        include_examples 'cross-project referenced object'
      end

      describe 'referencing a commit in another project' do
        let(:object)    { @commit2 }
        let(:reference) { "@#{@commit2.id}" }

        include_examples 'cross-project referenced object'
      end
    end

    describe "referencing a Jira issue" do
      let(:actual)   { "Reference to JIRA-#{issue.iid}" }
      let(:expected) { "http://jira.example/browse/JIRA-#{issue.iid}" }
      let(:reference) { "JIRA-#{issue.iid}" }

      before do
        jira = @project.create_jira_service if @project.jira_service.nil?
        properties = {"title"=>"JIRA tracker", "project_url"=>"http://jira.example/issues/?jql=project=A", "issues_url"=>"http://jira.example/browse/:id", "new_issue_url"=>"http://jira.example/secure/CreateIssue.jspa"}
        jira.update_attributes(properties: properties, active: true)
      end

      after do
        @project.jira_service.destroy! unless @project.jira_service.nil?
      end

      it "should link using a valid id" do
        expect(gfm(actual)).to match(expected)
      end

      it "should link with adjacent text" do
        # Wrap the reference in parenthesis
        expect(gfm(actual.gsub(reference, "(#{reference})"))).to match(expected)

        # Append some text to the end of the reference
        expect(gfm(actual.gsub(reference, "#{reference}, right?"))).
          to match(expected)
      end

      it "should keep whitespace intact" do
        actual   = "Referenced #{reference} already."
        expected = /Referenced <a.+>[^\s]+<\/a> already/
        expect(gfm(actual)).to match(expected)
      end

      it "should not link with an invalid id" do
        # Modify the reference string so it's still parsed, but is invalid
        invalid_reference = actual.gsub(/(\d+)$/, "r45")
        expect(gfm(invalid_reference)).to eq(invalid_reference)
      end

      it "should include a title attribute" do
        title = "Issue in JIRA tracker"
        expect(gfm(actual)).to match(/title="#{title}"/)
      end

      it "should include standard gfm classes" do
        expect(gfm(actual)).to match(/class="\s?gfm gfm-issue\s?"/)
      end
    end

    describe "referencing a merge request" do
      let(:object)    { merge_request }
      let(:reference) { "!#{merge_request.iid}" }

      include_examples 'referenced object'
    end

    describe "referencing a snippet" do
      let(:object)    { snippet }
      let(:reference) { "$#{snippet.id}" }
      let(:actual)   { "Reference to #{reference}" }
      let(:expected) { namespace_project_snippet_path(project.namespace, project, object) }

      it "should link using a valid id" do
        expect(gfm(actual)).to match(expected)
      end

      it "should link with adjacent text" do
        # Wrap the reference in parenthesis
        expect(gfm(actual.gsub(reference, "(#{reference})"))).to match(expected)

        # Append some text to the end of the reference
        expect(gfm(actual.gsub(reference, "#{reference}, right?"))).to match(expected)
      end

      it "should keep whitespace intact" do
        actual   = "Referenced #{reference} already."
        expected = /Referenced <a.+>[^\s]+<\/a> already/
        expect(gfm(actual)).to match(expected)
      end

      it "should not link with an invalid id" do
        # Modify the reference string so it's still parsed, but is invalid
        reference.gsub!(/^(.)(\d+)$/, '\1' + ('\2' * 2))
        expect(gfm(actual)).to eq(actual)
      end

      it "should include a title attribute" do
        title = "Snippet: #{object.title}"
        expect(gfm(actual)).to match(/title="#{title}"/)
      end

      it "should include standard gfm classes" do
        css = object.class.to_s.underscore
        expect(gfm(actual)).to match(/class="\s?gfm gfm-snippet\s?"/)
      end

    end

    describe "referencing multiple objects" do
      let(:actual) { "!#{merge_request.iid} -> #{commit.id} -> ##{issue.iid}" }

      it "should link to the merge request" do
        expected = namespace_project_merge_request_path(project.namespace, project, merge_request)
        expect(gfm(actual)).to match(expected)
      end

      it "should link to the commit" do
        expected = namespace_project_commit_path(project.namespace, project, commit)
        expect(gfm(actual)).to match(expected)
      end

      it "should link to the issue" do
        expected = namespace_project_issue_path(project.namespace, project, issue)
        expect(gfm(actual)).to match(expected)
      end
    end

    describe "emoji" do
      it "matches at the start of a string" do
        expect(gfm(":+1:")).to match(/<img/)
      end

      it "matches at the end of a string" do
        expect(gfm("This gets a :-1:")).to match(/<img/)
      end

      it "matches with adjacent text" do
        expect(gfm("+1 (:+1:)")).to match(/<img/)
      end

      it "has a title attribute" do
        expect(gfm(":-1:")).to match(/title=":-1:"/)
      end

      it "has an alt attribute" do
        expect(gfm(":-1:")).to match(/alt=":-1:"/)
      end

      it "has an emoji class" do
        expect(gfm(":+1:")).to match('class="emoji"')
      end

      it "sets height and width" do
        actual = gfm(":+1:")
        expect(actual).to match(/width="20"/)
        expect(actual).to match(/height="20"/)
      end

      it "keeps whitespace intact" do
        expect(gfm('This deserves a :+1: big time.')).
          to match(/deserves a <img.+> big time/)
      end

      it "ignores invalid emoji" do
        expect(gfm(":invalid-emoji:")).not_to match(/<img/)
      end

      it "should work independent of reference links (i.e. without @project being set)" do
        @project = nil
        expect(gfm(":+1:")).to match(/<img/)
      end
    end
  end

  describe "#link_to_gfm" do
    let(:commit_path) { namespace_project_commit_path(project.namespace, project, commit) }
    let(:issues)      { create_list(:issue, 2, project: project) }

    it "should handle references nested in links with all the text" do
      actual = link_to_gfm("This should finally fix ##{issues[0].iid} and ##{issues[1].iid} for real", commit_path)

      # Break the result into groups of links with their content, without
      # closing tags
      groups = actual.split("</a>")

      # Leading commit link
      expect(groups[0]).to match(/href="#{commit_path}"/)
      expect(groups[0]).to match(/This should finally fix $/)

      # First issue link
      expect(groups[1]).
        to match(/href="#{namespace_project_issue_path(project.namespace, project, issues[0])}"/)
      expect(groups[1]).to match(/##{issues[0].iid}$/)

      # Internal commit link
      expect(groups[2]).to match(/href="#{commit_path}"/)
      expect(groups[2]).to match(/ and /)

      # Second issue link
      expect(groups[3]).
        to match(/href="#{namespace_project_issue_path(project.namespace, project, issues[1])}"/)
      expect(groups[3]).to match(/##{issues[1].iid}$/)

      # Trailing commit link
      expect(groups[4]).to match(/href="#{commit_path}"/)
      expect(groups[4]).to match(/ for real$/)
    end

    it "should forward HTML options" do
      actual = link_to_gfm("Fixed in #{commit.id}", commit_path, class: 'foo')
      expect(actual).to have_selector 'a.gfm.gfm-commit.foo'
    end

    it "escapes HTML passed in as the body" do
      actual = "This is a <h1>test</h1> - see ##{issues[0].iid}"
      expect(link_to_gfm(actual, commit_path)).
        to match('&lt;h1&gt;test&lt;/h1&gt;')
    end
  end

  describe "#markdown" do
    it "should handle references in paragraphs" do
      actual = "\n\nLorem ipsum dolor sit amet. #{commit.id} Nam pulvinar sapien eget.\n"
      expected = namespace_project_commit_path(project.namespace, project, commit)
      expect(markdown(actual)).to match(expected)
    end

    it "should handle references in headers" do
      actual = "\n# Working around ##{issue.iid}\n## Apply !#{merge_request.iid}"

      expect(markdown(actual, no_header_anchors: true)).
        to match(%r{<h1[^<]*>Working around <a.+>##{issue.iid}</a></h1>})
      expect(markdown(actual, no_header_anchors: true)).
        to match(%r{<h2[^<]*>Apply <a.+>!#{merge_request.iid}</a></h2>})
    end

    it "should add ids and links to headers" do
      # Test every rule except nested tags.
      text = '..Ab_c-d. e..'
      id = 'ab_c-d-e'
      expect(markdown("# #{text}")).
        to match(%r{<h1 id="#{id}">#{text}<a href="[^"]*##{id}"></a></h1>})
      expect(markdown("# #{text}", {no_header_anchors:true})).
      to eq("<h1>#{text}</h1>")

      id = 'link-text'
      expect(markdown("# [link text](url) ![img alt](url)")).to match(
        %r{<h1 id="#{id}"><a href="[^"]*url">link text</a> <img[^>]*><a href="[^"]*##{id}"></a></h1>}
      )
    end

    it "should handle references in lists" do
      project.team << [user, :master]

      actual = "\n* dark: ##{issue.iid}\n* light by @#{member.user.username}"

      expect(markdown(actual)).
        to match(%r{<li>dark: <a.+>##{issue.iid}</a></li>})
      expect(markdown(actual)).
        to match(%r{<li>light by <a.+>@#{member.user.username}</a></li>})
    end

    it "should not link the apostrophe to issue 39" do
      project.team << [user, :master]
      allow(project.issues).
        to receive(:where).with(iid: '39').and_return([issue])

      actual   = "Yes, it is @#{member.user.username}'s task."
      expected = /Yes, it is <a.+>@#{member.user.username}<\/a>'s task/
      expect(markdown(actual)).to match(expected)
    end

    it "should not link the apostrophe to issue 39 in code blocks" do
      project.team << [user, :master]
      allow(project.issues).
        to receive(:where).with(iid: '39').and_return([issue])

      actual   = "Yes, `it is @#{member.user.username}'s task.`"
      expected = /Yes, <code>it is @gfm\'s task.<\/code>/
      expect(markdown(actual)).to match(expected)
    end

    it "should handle references in <em>" do
      actual = "Apply _!#{merge_request.iid}_ ASAP"

      expect(markdown(actual)).
        to match(%r{Apply <em><a.+>!#{merge_request.iid}</a></em>})
    end

    it "should handle tables" do
      actual = %Q{| header 1 | header 2 |
| -------- | -------- |
| cell 1   | cell 2   |
| cell 3   | cell 4   |}

      expect(markdown(actual)).to match(/\A<table/)
    end

    it "should leave code blocks untouched" do
      allow(helper).to receive(:user_color_scheme_class).and_return(:white)

      target_html = "<pre class=\"code highlight white plaintext\"><code>some code from $#{snippet.id}\nhere too\n</code></pre>\n"

      expect(helper.markdown("\n    some code from $#{snippet.id}\n    here too\n")).
        to eq(target_html)
      expect(helper.markdown("\n```\nsome code from $#{snippet.id}\nhere too\n```\n")).
        to eq(target_html)
    end

    it "should leave inline code untouched" do
      expect(markdown("\nDon't use `$#{snippet.id}` here.\n")).to eq(
        "<p>Don't use <code>$#{snippet.id}</code> here.</p>\n"
      )
    end

    it "should leave ref-like autolinks untouched" do
      expect(markdown("look at http://example.tld/#!#{merge_request.iid}")).to eq("<p>look at <a href=\"http://example.tld/#!#{merge_request.iid}\">http://example.tld/#!#{merge_request.iid}</a></p>\n")
    end

    it "should leave ref-like href of 'manual' links untouched" do
      expect(markdown("why not [inspect !#{merge_request.iid}](http://example.tld/#!#{merge_request.iid})")).to eq("<p>why not <a href=\"http://example.tld/#!#{merge_request.iid}\">inspect </a><a class=\"gfm gfm-merge_request \" href=\"#{namespace_project_merge_request_url(project.namespace, project, merge_request)}\" title=\"Merge Request: #{merge_request.title}\">!#{merge_request.iid}</a><a href=\"http://example.tld/#!#{merge_request.iid}\"></a></p>\n")
    end

    it "should leave ref-like src of images untouched" do
      expect(markdown("screen shot: ![some image](http://example.tld/#!#{merge_request.iid})")).to eq("<p>screen shot: <img src=\"http://example.tld/#!#{merge_request.iid}\" alt=\"some image\"></p>\n")
    end

    it "should generate absolute urls for refs" do
      expect(markdown("##{issue.iid}")).to include(namespace_project_issue_path(project.namespace, project, issue))
    end

    it "should generate absolute urls for emoji" do
      expect(markdown(':smile:')).to(
        include(%(src="#{Gitlab.config.gitlab.url}/assets/emoji/smile.png))
      )
    end

    it "should generate absolute urls for emoji if relative url is present" do
      allow(Gitlab.config.gitlab).to receive(:url).and_return('http://localhost/gitlab/root')
      expect(markdown(":smile:")).to include("src=\"http://localhost/gitlab/root/assets/emoji/smile.png")
    end

    it "should generate absolute urls for emoji if asset_host is present" do
      allow(Gitlab::Application.config).to receive(:asset_host).and_return("https://cdn.example.com")
      ActionView::Base.any_instance.stub_chain(:config, :asset_host).and_return("https://cdn.example.com")
      expect(markdown(":smile:")).to include("src=\"https://cdn.example.com/assets/emoji/smile.png")
    end


    it "should handle relative urls for a file in master" do
      actual = "[GitLab API doc](doc/api/README.md)\n"
      expected = "<p><a href=\"/#{project.path_with_namespace}/blob/#{@ref}/doc/api/README.md\">GitLab API doc</a></p>\n"
      expect(markdown(actual)).to match(expected)
    end

    it "should handle relative urls for a file in master with an anchor" do
      actual = "[GitLab API doc](doc/api/README.md#section)\n"
      expected = "<p><a href=\"/#{project.path_with_namespace}/blob/#{@ref}/doc/api/README.md#section\">GitLab API doc</a></p>\n"
      expect(markdown(actual)).to match(expected)
    end

    it "should not handle relative urls for the current file with an anchor" do
      actual = "[GitLab API doc](#section)\n"
      expected = "<p><a href=\"#section\">GitLab API doc</a></p>\n"
      expect(markdown(actual)).to match(expected)
    end

    it "should handle relative urls for a directory in master" do
      actual = "[GitLab API doc](doc/api)\n"
      expected = "<p><a href=\"/#{project.path_with_namespace}/tree/#{@ref}/doc/api\">GitLab API doc</a></p>\n"
      expect(markdown(actual)).to match(expected)
    end

    it "should handle absolute urls" do
      actual = "[GitLab](https://www.gitlab.com)\n"
      expected = "<p><a href=\"https://www.gitlab.com\">GitLab</a></p>\n"
      expect(markdown(actual)).to match(expected)
    end

    it "should handle relative urls in reference links for a file in master" do
      actual = "[GitLab API doc][GitLab readme]\n [GitLab readme]: doc/api/README.md\n"
      expected = "<p><a href=\"/#{project.path_with_namespace}/blob/#{@ref}/doc/api/README.md\">GitLab API doc</a></p>\n"
      expect(markdown(actual)).to match(expected)
    end

    it "should handle relative urls in reference links for a directory in master" do
      actual = "[GitLab API doc directory][GitLab readmes]\n [GitLab readmes]: doc/api/\n"
      expected = "<p><a href=\"/#{project.path_with_namespace}/tree/#{@ref}/doc/api\">GitLab API doc directory</a></p>\n"
      expect(markdown(actual)).to match(expected)
    end

     it "should not handle malformed relative urls in reference links for a file in master" do
      actual = "[GitLab readme]: doc/api/README.md\n"
      expected = ""
      expect(markdown(actual)).to match(expected)
    end
  end

  describe 'markdown for empty repository' do
    before do
      @project = empty_project
      @repository = empty_project.repository
    end

    it "should not touch relative urls" do
      actual = "[GitLab API doc][GitLab readme]\n [GitLab readme]: doc/api/README.md\n"
      expected = "<p><a href=\"doc/api/README.md\">GitLab API doc</a></p>\n"
      expect(markdown(actual)).to match(expected)
    end
  end

  describe "#render_wiki_content" do
    before do
      @wiki = double('WikiPage')
      allow(@wiki).to receive(:content).and_return('wiki content')
    end

    it "should use GitLab Flavored Markdown for markdown files" do
      allow(@wiki).to receive(:format).and_return(:markdown)

      expect(helper).to receive(:markdown).with('wiki content')

      helper.render_wiki_content(@wiki)
    end

    it "should use the Gollum renderer for all other file types" do
      allow(@wiki).to receive(:format).and_return(:rdoc)
      formatted_content_stub = double('formatted_content')
      expect(formatted_content_stub).to receive(:html_safe)
      allow(@wiki).to receive(:formatted_content).and_return(formatted_content_stub)

      helper.render_wiki_content(@wiki)
    end
  end

  describe '#gfm_with_tasks' do
    before(:all) do
      @source_text_asterisk = <<EOT.gsub(/^\s{8}/, '')
        * [ ] valid unchecked task
        * [x] valid lowercase checked task
        * [X] valid uppercase checked task
            * [ ] valid unchecked nested task
            * [x] valid checked nested task

        [ ] not an unchecked task - no list item
        [x] not a checked task - no list item

        * [  ] not an unchecked task - too many spaces
        * [x ] not a checked task - too many spaces
        * [] not an unchecked task - no spaces
        * Not a task [ ] - not at beginning
EOT

      @source_text_dash = <<EOT.gsub(/^\s{8}/, '')
        - [ ] valid unchecked task
        - [x] valid lowercase checked task
        - [X] valid uppercase checked task
            - [ ] valid unchecked nested task
            - [x] valid checked nested task
EOT
    end

    it 'should render checkboxes at beginning of asterisk list items' do
      rendered_text = markdown(@source_text_asterisk, parse_tasks: true)

      expect(rendered_text).to match(/<input.*checkbox.*valid unchecked task/)
      expect(rendered_text).to match(
        /<input.*checkbox.*valid lowercase checked task/
      )
      expect(rendered_text).to match(
        /<input.*checkbox.*valid uppercase checked task/
      )
    end

    it 'should render checkboxes at beginning of dash list items' do
      rendered_text = markdown(@source_text_dash, parse_tasks: true)

      expect(rendered_text).to match(/<input.*checkbox.*valid unchecked task/)
      expect(rendered_text).to match(
        /<input.*checkbox.*valid lowercase checked task/
      )
      expect(rendered_text).to match(
        /<input.*checkbox.*valid uppercase checked task/
      )
    end

    it 'should not be confused by whitespace before bullets' do
      rendered_text_asterisk = markdown(@source_text_asterisk,
                                        parse_tasks: true)
      rendered_text_dash = markdown(@source_text_dash, parse_tasks: true)

      expect(rendered_text_asterisk).to match(
        /<input.*checkbox.*valid unchecked nested task/
      )
      expect(rendered_text_asterisk).to match(
        /<input.*checkbox.*valid checked nested task/
      )
      expect(rendered_text_dash).to match(
        /<input.*checkbox.*valid unchecked nested task/
      )
      expect(rendered_text_dash).to match(
        /<input.*checkbox.*valid checked nested task/
      )
    end

    it 'should not render checkboxes outside of list items' do
      rendered_text = markdown(@source_text_asterisk, parse_tasks: true)

      expect(rendered_text).not_to match(
        /<input.*checkbox.*not an unchecked task - no list item/
      )
      expect(rendered_text).not_to match(
        /<input.*checkbox.*not a checked task - no list item/
      )
    end

    it 'should not render checkboxes with invalid formatting' do
      rendered_text = markdown(@source_text_asterisk, parse_tasks: true)

      expect(rendered_text).not_to match(
        /<input.*checkbox.*not an unchecked task - too many spaces/
      )
      expect(rendered_text).not_to match(
        /<input.*checkbox.*not a checked task - too many spaces/
      )
      expect(rendered_text).not_to match(
        /<input.*checkbox.*not an unchecked task - no spaces/
      )
      expect(rendered_text).not_to match(
        /Not a task.*<input.*checkbox.*not at beginning/
      )
    end
  end
end
