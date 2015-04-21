require 'spec_helper'

describe GitlabMarkdownHelper do
  include ApplicationHelper
  include IssuesHelper

  # TODO: Properly test this
  def can?(*)
    true
  end

  let!(:project) { create(:project) }
  let(:empty_project) { create(:empty_project) }

  let(:user)          { create(:user, username: 'gfm') }
  let(:commit)        { project.repository.commit }
  let(:earlier_commit){ project.repository.commit("HEAD~2") }
  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:snippet)       { create(:project_snippet, project: project) }
  let(:member)        { project.project_members.where(user_id: user).first }

  # Helper expects a current_user method.
  let(:current_user) { user }

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
    it "should forward HTML options to links" do
      expect(gfm("Fixed in #{commit.id}", @project, class: 'foo')).
          to have_selector('a.gfm.foo')
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

    # TODO (rspeicher): These tests belong in the emoji filter spec
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

    context 'parse_tasks: true' do
      before(:all) do
        @source_text_asterisk = <<-EOT.strip_heredoc
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

        @source_text_dash = <<-EOT.strip_heredoc
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

      it 'should render checkboxes for nested tasks' do
        rendered_text = markdown(@source_text_asterisk, parse_tasks: true)

        expect(rendered_text).to match(
          /<input.*checkbox.*valid unchecked nested task/
        )
        expect(rendered_text).to match(
          /<input.*checkbox.*valid checked nested task/
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
    # TODO (rspeicher) - This block tests multiple different contexts. Break this up!

    # REFERENCES (PART TWO: THE REVENGE) ---------------------------------------

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

    it "should handle references in <em>" do
      actual = "Apply _!#{merge_request.iid}_ ASAP"

      expect(markdown(actual)).
        to match(%r{Apply <em><a.+>!#{merge_request.iid}</a></em>})
    end

    # CODE BLOCKS -------------------------------------------------------------

    it "should leave code blocks untouched" do
      allow(helper).to receive(:current_user).and_return(user)
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

    # REF-LIKE AUTOLINKS? -----------------------------------------------------
    # Basically: Don't parse references inside `<a>` tags.

    it "should leave ref-like autolinks untouched" do
      expect(markdown("look at http://example.tld/#!#{merge_request.iid}")).to eq("<p>look at <a href=\"http://example.tld/#!#{merge_request.iid}\">http://example.tld/#!#{merge_request.iid}</a></p>\n")
    end

    it "should leave ref-like href of 'manual' links untouched" do
      expect(markdown("why not [inspect !#{merge_request.iid}](http://example.tld/#!#{merge_request.iid})")).to eq("<p>why not <a href=\"http://example.tld/#!#{merge_request.iid}\">inspect </a><a href=\"#{namespace_project_merge_request_path(project.namespace, project, merge_request)}\" title=\"Merge Request: #{merge_request.title}\" class=\"gfm gfm-merge_request\">!#{merge_request.iid}</a><a href=\"http://example.tld/#!#{merge_request.iid}\"></a></p>\n")
    end

    it "should leave ref-like src of images untouched" do
      expect(markdown("screen shot: ![some image](http://example.tld/#!#{merge_request.iid})")).to eq("<p>screen shot: <img src=\"http://example.tld/#!#{merge_request.iid}\" alt=\"some image\"></p>\n")
    end

    it "should generate absolute urls for refs" do
      expect(markdown("##{issue.iid}")).to include(namespace_project_issue_path(project.namespace, project, issue))
    end

    # EMOJI -------------------------------------------------------------------

    it "should generate absolute urls for emoji" do
      # TODO (rspeicher): Why isn't this with the emoji tests?
      expect(markdown(':smile:')).to(
        include(%(src="#{Gitlab.config.gitlab.url}/assets/emoji/#{Emoji.emoji_filename('smile')}.png))
      )
    end

    it "should generate absolute urls for emoji if relative url is present" do
      # TODO (rspeicher): Why isn't this with the emoji tests?
      allow(Gitlab.config.gitlab).to receive(:url).and_return('http://localhost/gitlab/root')
      expect(markdown(":smile:")).to include("src=\"http://localhost/gitlab/root/assets/emoji/#{Emoji.emoji_filename('smile')}.png")
    end

    it "should generate absolute urls for emoji if asset_host is present" do
      # TODO (rspeicher): Why isn't this with the emoji tests?
      allow(Gitlab::Application.config).to receive(:asset_host).and_return("https://cdn.example.com")
      ActionView::Base.any_instance.stub_chain(:config, :asset_host).and_return("https://cdn.example.com")
      expect(markdown(":smile:")).to include("src=\"https://cdn.example.com/assets/emoji/#{Emoji.emoji_filename('smile')}.png")
    end

    # RELATIVE URLS -----------------------------------------------------------
    # TODO (rspeicher): These belong in a relative link filter spec

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

    it 'should allow whitelisted HTML tags from the user' do
      actual = '<dl><dt>Term</dt><dd>Definition</dd></dl>'
      expect(markdown(actual)).to match(actual)
    end

    # SANITIZATION ------------------------------------------------------------

    it 'should sanitize tags that are not whitelisted' do
      actual = '<textarea>no inputs allowed</textarea> <blink>no blinks</blink>'
      expected = 'no inputs allowed no blinks'
      expect(markdown(actual)).to match(expected)
      expect(markdown(actual)).not_to match('<.textarea>')
      expect(markdown(actual)).not_to match('<.blink>')
    end

    it 'should allow whitelisted tag attributes from the user' do
      actual = '<a class="custom">link text</a>'
      expect(markdown(actual)).to match(actual)
    end

    it 'should sanitize tag attributes that are not whitelisted' do
      actual = '<a href="http://example.com/bar.html" foo="bar">link text</a>'
      expected = '<a href="http://example.com/bar.html">link text</a>'
      expect(markdown(actual)).to match(expected)
    end

    it 'should sanitize javascript in attributes' do
      actual = %q(<a href="javascript:alert('foo')">link text</a>)
      expected = '<a>link text</a>'
      expect(markdown(actual)).to match(expected)
    end
  end

  # TODO (rspeicher): This should be a context of relative link specs, not its own thing
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

  describe '#render_wiki_content' do
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
end
