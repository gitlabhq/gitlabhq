require 'spec_helper'

describe GitlabMarkdownHelper do
  include ApplicationHelper

  let!(:project) { create(:project) }

  let(:user)          { create(:user, username: 'gfm') }
  let(:commit)        { project.commit }
  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:snippet)       { create(:project_snippet, project: project) }

  # Helper expects a current_user method.
  let(:current_user) { user }

  before do
    # Helper expects a @project instance variable
    @project = project
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
  end

  describe '#link_to_gfm' do
    let(:commit_path) { namespace_project_commit_path(project.namespace, project, commit) }
    let(:issues)      { create_list(:issue, 2, project: project) }

    it 'should handle references nested in links with all the text' do
      actual = link_to_gfm("This should finally fix ##{issues[0].iid} and ##{issues[1].iid} for real", commit_path)
      doc = Nokogiri::HTML.parse(actual)

      # Make sure we didn't create invalid markup
      expect(doc.errors).to be_empty

      # Leading commit link
      expect(doc.css('a')[0].attr('href')).to eq commit_path
      expect(doc.css('a')[0].text).to eq 'This should finally fix '

      # First issue link
      expect(doc.css('a')[1].attr('href')).
        to eq namespace_project_issue_path(project.namespace, project, issues[0])
      expect(doc.css('a')[1].text).to eq "##{issues[0].iid}"

      # Internal commit link
      expect(doc.css('a')[2].attr('href')).to eq commit_path
      expect(doc.css('a')[2].text).to eq ' and '

      # Second issue link
      expect(doc.css('a')[3].attr('href')).
        to eq namespace_project_issue_path(project.namespace, project, issues[1])
      expect(doc.css('a')[3].text).to eq "##{issues[1].iid}"

      # Trailing commit link
      expect(doc.css('a')[4].attr('href')).to eq commit_path
      expect(doc.css('a')[4].text).to eq ' for real'
    end

    it 'should forward HTML options' do
      actual = link_to_gfm("Fixed in #{commit.id}", commit_path, class: 'foo')
      doc = Nokogiri::HTML.parse(actual)

      expect(doc.css('a')).to satisfy do |v|
        # 'foo' gets added to all links
        v.all? { |a| a.attr('class').match(/foo$/) }
      end
    end

    it "escapes HTML passed in as the body" do
      actual = "This is a <h1>test</h1> - see ##{issues[0].iid}"
      expect(link_to_gfm(actual, commit_path)).
        to match('&lt;h1&gt;test&lt;/h1&gt;')
    end
  end

  describe "#markdown" do
    # TODO (rspeicher): These belong in a relative link filter spec
    context 'relative links' do
      context 'with a valid repository' do
        before do
          @repository = project.repository
          @ref = 'markdown'
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

      context 'with an empty repository' do
        before do
          @project = create(:empty_project)
          @repository = @project.repository
        end

        it "should not touch relative urls" do
          actual = "[GitLab API doc][GitLab readme]\n [GitLab readme]: doc/api/README.md\n"
          expected = "<p><a href=\"doc/api/README.md\">GitLab API doc</a></p>\n"
          expect(markdown(actual)).to match(expected)
        end
      end
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
