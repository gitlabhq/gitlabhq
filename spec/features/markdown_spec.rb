require 'spec_helper'
require 'erb'

# This feature spec is intended to be a comprehensive exercising of all of
# GitLab's non-standard Markdown parsing and the integration thereof.
#
# These tests should be very high-level. Anything low-level belongs in the specs
# for the corresponding HTML::Pipeline filter or helper method.
#
# The idea is to pass a Markdown document through our entire processing stack.
#
# The process looks like this:
#
#   Raw Markdown
#   -> `markdown` helper
#     -> Redcarpet::Render::GitlabHTML converts Markdown to HTML
#       -> Post-process HTML
#         -> `gfm_with_options` helper
#           -> HTML::Pipeline
#             -> Sanitize
#             -> Emoji
#             -> Table of Contents
#             -> Autolinks
#               -> Rinku (http, https, ftp)
#               -> Other schemes
#             -> References
#             -> TaskList
#           -> `html_safe`
#           -> Template
#
# See the MarkdownFeature class for setup details.

describe 'GitLab Markdown' do
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include Capybara::Node::Matchers
  include GitlabMarkdownHelper

  # `markdown` calls these two methods
  def current_user
    @feat.user
  end

  def user_color_scheme_class
    :white
  end

  # Let's only parse this thing once
  before(:all) do
    @feat = MarkdownFeature.new

    # `markdown` expects a `@project` variable
    @project = @feat.project

    @md = markdown(@feat.raw_markdown)
    @doc = Nokogiri::HTML::DocumentFragment.parse(@md)
  end

  after(:all) do
    @feat.teardown
  end

  # Given a header ID, goes to that element's parent (the header itself), then
  # its next sibling element (the body).
  def get_section(id)
    @doc.at_css("##{id}").parent.next_element
  end

  # it 'writes to a file' do
  #   File.open(Rails.root.join('tmp/capybara/markdown_spec.html'), 'w') do |file|
  #     file.puts @md
  #   end
  # end

  describe 'Markdown' do
    describe 'No Intra Emphasis' do
      it 'does not parse emphasis inside of words' do
        body = get_section('no-intra-emphasis')
        expect(body.to_html).not_to match('foo<em>bar</em>baz')
      end
    end

    describe 'Tables' do
      it 'parses table Markdown' do
        body = get_section('tables')
        expect(body).to have_selector('th:contains("Header")')
        expect(body).to have_selector('th:contains("Row")')
        expect(body).to have_selector('th:contains("Example")')
      end

      it 'allows Markdown in tables' do
        expect(@doc.at_css('td:contains("Baz")').children.to_html).
          to eq '<strong>Baz</strong>'
      end
    end

    describe 'Fenced Code Blocks' do
      it 'parses fenced code blocks' do
        expect(@doc).to have_selector('pre.code.highlight.white.c')
        expect(@doc).to have_selector('pre.code.highlight.white.python')
      end
    end

    describe 'Strikethrough' do
      it 'parses strikethroughs' do
        expect(@doc).to have_selector(%{del:contains("and this text doesn't")})
      end
    end

    describe 'Superscript' do
      it 'parses superscript' do
        body = get_section('superscript')
        expect(body.to_html).to match('1<sup>st</sup>')
        expect(body.to_html).to match('2<sup>nd</sup>')
      end
    end
  end

  describe 'HTML::Pipeline' do
    describe 'SanitizationFilter' do
      it 'uses a permissive whitelist' do
        expect(@doc).to have_selector('b:contains("b tag")')
        expect(@doc).to have_selector('em:contains("em tag")')
        expect(@doc).to have_selector('code:contains("code tag")')
        expect(@doc).to have_selector('kbd:contains("s")')
        expect(@doc).to have_selector('strike:contains(Emoji)')
        expect(@doc).to have_selector('img[src*="smile.png"]')
        expect(@doc).to have_selector('br')
        expect(@doc).to have_selector('hr')
      end

      it 'permits span elements' do
        expect(@doc).to have_selector('span:contains("span tag")')
      end

      it 'permits table alignment' do
        expect(@doc.at_css('th:contains("Header")')['style']).to eq 'text-align: center'
        expect(@doc.at_css('th:contains("Row")')['style']).to eq 'text-align: right'
        expect(@doc.at_css('th:contains("Example")')['style']).to eq 'text-align: left'

        expect(@doc.at_css('td:contains("Foo")')['style']).to eq 'text-align: center'
        expect(@doc.at_css('td:contains("Bar")')['style']).to eq 'text-align: right'
        expect(@doc.at_css('td:contains("Baz")')['style']).to eq 'text-align: left'
      end

      it 'removes `rel` attribute from links' do
        body = get_section('sanitizationfilter')
        expect(body).not_to have_selector('a[rel="bookmark"]')
      end

      it "removes `href` from `a` elements if it's fishy" do
        expect(@doc).not_to have_selector('a[href*="javascript"]')
      end
    end

    describe 'Escaping' do
      let(:table) { @doc.css('table').last.at_css('tbody') }

      it 'escapes non-tag angle brackets' do
        expect(table.at_xpath('.//tr[1]/td[3]').inner_html).to eq '1 &lt; 3 &amp; 5'
      end
    end

    describe 'Edge Cases' do
      it 'allows markup inside link elements' do
        expect(@doc.at_css('a[href="#link-emphasis"]').to_html).
          to eq %{<a href="#link-emphasis"><em>text</em></a>}

        expect(@doc.at_css('a[href="#link-strong"]').to_html).
          to eq %{<a href="#link-strong"><strong>text</strong></a>}

        expect(@doc.at_css('a[href="#link-code"]').to_html).
          to eq %{<a href="#link-code"><code>text</code></a>}
      end
    end

    describe 'EmojiFilter' do
      it 'parses Emoji' do
        expect(@doc).to have_selector('img.emoji', count: 10)
      end
    end

    describe 'TableOfContentsFilter' do
      it 'creates anchors inside header elements' do
        expect(@doc).to have_selector('h1 a#gitlab-markdown')
        expect(@doc).to have_selector('h2 a#markdown')
        expect(@doc).to have_selector('h3 a#autolinkfilter')
      end
    end

    describe 'AutolinkFilter' do
      let(:list) { get_section('autolinkfilter').next_element }

      def item(index)
        list.at_css("li:nth-child(#{index})")
      end

      it 'autolinks http://' do
        expect(item(1).children.first.name).to eq 'a'
        expect(item(1).children.first['href']).to eq 'http://about.gitlab.com/'
      end

      it 'autolinks https://' do
        expect(item(2).children.first.name).to eq 'a'
        expect(item(2).children.first['href']).to eq 'https://google.com/'
      end

      it 'autolinks ftp://' do
        expect(item(3).children.first.name).to eq 'a'
        expect(item(3).children.first['href']).to eq 'ftp://ftp.us.debian.org/debian/'
      end

      it 'autolinks smb://' do
        expect(item(4).children.first.name).to eq 'a'
        expect(item(4).children.first['href']).to eq 'smb://foo/bar/baz'
      end

      it 'autolinks irc://' do
        expect(item(5).children.first.name).to eq 'a'
        expect(item(5).children.first['href']).to eq 'irc://irc.freenode.net/git'
      end

      it 'autolinks short, invalid URLs' do
        expect(item(6).children.first.name).to eq 'a'
        expect(item(6).children.first['href']).to eq 'http://localhost:3000'
      end

      %w(code a kbd).each do |elem|
        it "ignores links inside '#{elem}' element" do
          body = get_section('autolinkfilter')
          expect(body).not_to have_selector("#{elem} a")
        end
      end
    end

    describe 'ExternalLinkFilter' do
      let(:links) { get_section('externallinkfilter').next_element }

      it 'adds nofollow to external link' do
        expect(links.css('a').first.to_html).to match 'nofollow'
      end

      it 'ignores internal link' do
        expect(links.css('a').last.to_html).not_to match 'nofollow'
      end
    end

    describe 'ReferenceFilter' do
      it 'handles references in headers' do
        header = @doc.at_css('#reference-filters-eg-1').parent

        expect(header.css('a').size).to eq 2
      end

      it "handles references in Markdown" do
        body = get_section('reference-filters-eg-1')
        expect(body).to have_selector('em a.gfm-merge_request', count: 1)
      end

      it 'parses user references' do
        body = get_section('userreferencefilter')
        expect(body).to have_selector('a.gfm.gfm-project_member', count: 3)
      end

      it 'parses issue references' do
        body = get_section('issuereferencefilter')
        expect(body).to have_selector('a.gfm.gfm-issue', count: 2)
      end

      it 'parses merge request references' do
        body = get_section('mergerequestreferencefilter')
        expect(body).to have_selector('a.gfm.gfm-merge_request', count: 2)
      end

      it 'parses snippet references' do
        body = get_section('snippetreferencefilter')
        expect(body).to have_selector('a.gfm.gfm-snippet', count: 2)
      end

      it 'parses commit range references' do
        body = get_section('commitrangereferencefilter')
        expect(body).to have_selector('a.gfm.gfm-commit_range', count: 2)
      end

      it 'parses commit references' do
        body = get_section('commitreferencefilter')
        expect(body).to have_selector('a.gfm.gfm-commit', count: 2)
      end

      it 'parses label references' do
        body = get_section('labelreferencefilter')
        expect(body).to have_selector('a.gfm.gfm-label', count: 3)
      end
    end

    describe 'Task Lists' do
      it 'generates task lists' do
        body = get_section('task-lists')
        expect(body).to have_selector('ul.task-list', count: 2)
        expect(body).to have_selector('li.task-list-item', count: 7)
        expect(body).to have_selector('input[checked]', count: 3)
      end
    end
  end
end

# This is a helper class used by the GitLab Markdown feature spec
#
# Because the feature spec only cares about the output of the Markdown, and the
# test setup and teardown and parsing is fairly expensive, we only want to do it
# once. Unfortunately RSpec will not let you access `let`s in a `before(:all)`
# block, so we fake it by encapsulating all the shared setup in this class.
#
# The class renders `spec/fixtures/markdown.md.erb` using ERB, allowing for
# reference to the factory-created objects.
class MarkdownFeature
  include FactoryGirl::Syntax::Methods

  def initialize
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def user
    @user ||= create(:user)
  end

  def group
    unless @group
      @group = create(:group)
      @group.add_user(user, Gitlab::Access::DEVELOPER)
    end

    @group
  end

  # Direct references ----------------------------------------------------------

  def project
    @project ||= create(:project)
  end

  def issue
    @issue ||= create(:issue, project: project)
  end

  def merge_request
    @merge_request ||= create(:merge_request, :simple, source_project: project)
  end

  def snippet
    @snippet ||= create(:project_snippet, project: project)
  end

  def commit
    @commit ||= project.repository.commit
  end

  def commit_range
    unless @commit_range
      commit2 = project.repository.commit('HEAD~3')
      @commit_range = CommitRange.new("#{commit.id}...#{commit2.id}")
    end

    @commit_range
  end

  def simple_label
    @simple_label ||= create(:label, name: 'gfm', project: project)
  end

  def label
    @label ||= create(:label, name: 'awaiting feedback', project: project)
  end

  # Cross-references -----------------------------------------------------------

  def xproject
    unless @xproject
      namespace = create(:namespace, name: 'cross-reference')
      @xproject = create(:project, namespace: namespace)
      @xproject.team << [user, :developer]
    end

    @xproject
  end

  # Shortcut to "cross-reference/project"
  def xref
    xproject.path_with_namespace
  end

  def xissue
    @xissue ||= create(:issue, project: xproject)
  end

  def xmerge_request
    @xmerge_request ||= create(:merge_request, :simple, source_project: xproject)
  end

  def xsnippet
    @xsnippet ||= create(:project_snippet, project: xproject)
  end

  def xcommit
    @xcommit ||= xproject.repository.commit
  end

  def xcommit_range
    unless @xcommit_range
      xcommit2 = xproject.repository.commit('HEAD~2')
      @xcommit_range = CommitRange.new("#{xcommit.id}...#{xcommit2.id}")
    end

    @xcommit_range
  end

  def raw_markdown
    fixture = Rails.root.join('spec/fixtures/markdown.md.erb')
    ERB.new(File.read(fixture)).result(binding)
  end
end
