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
#             -> RelativeLink
#             -> Emoji
#             -> Table of Contents
#             -> Autolinks
#               -> Rinku (http, https, ftp)
#               -> Other schemes
#             -> ExternalLink
#             -> References
#             -> TaskList
#           -> `html_safe`
#           -> Template
#
# See the MarkdownFeature class for setup details.

describe 'GitLab Markdown', feature: true do
  include Capybara::Node::Matchers
  include GitlabMarkdownHelper

  # Let's only parse this thing once
  before(:all) do
    @feat = MarkdownFeature.new

    # `gfm_with_options` depends on a `@project` variable
    @project = @feat.project

    @html = markdown(@feat.raw_markdown)
  end

  after(:all) do
    @feat.teardown
  end

  def doc
    @doc ||= Nokogiri::HTML::DocumentFragment.parse(@html)
  end

  # Given a header ID, goes to that element's parent (the header itself), then
  # its next sibling element (the body).
  def get_section(id)
    doc.at_css("##{id}").parent.next_element
  end

  # Sometimes it can be useful to see the parsed output of the Markdown document
  # for debugging. Uncomment this block to write the output to
  # tmp/capybara/markdown_spec.html.
  #
  # it 'writes to a file' do
  #   File.open(Rails.root.join('tmp/capybara/markdown_spec.html'), 'w') do |file|
  #     file.puts @html
  #   end
  # end

  describe 'Redcarpet extensions' do
    describe 'No Intra Emphasis' do
      it 'does not parse emphasis inside of words' do
        body = get_section('no-intra-emphasis')
        expect(body.to_html).not_to match('foo<em>bar</em>baz')
      end
    end

    describe 'Tables' do
      it 'parses table Markdown' do
        body = get_section('tables')

        aggregate_failures do
          expect(body).to have_selector('th:contains("Header")')
          expect(body).to have_selector('th:contains("Row")')
          expect(body).to have_selector('th:contains("Example")')
        end
      end

      it 'allows Markdown in tables' do
        expect(doc.at_css('td:contains("Baz")').children.to_html).
          to eq '<strong>Baz</strong>'
      end
    end

    describe 'Fenced Code Blocks' do
      it 'parses fenced code blocks' do
        aggregate_failures do
          expect(doc).to have_selector('pre.code.highlight.white.c')
          expect(doc).to have_selector('pre.code.highlight.white.python')
        end
      end
    end

    describe 'Strikethrough' do
      it 'parses strikethroughs' do
        expect(doc).to have_selector(%{del:contains("and this text doesn't")})
      end
    end

    describe 'Superscript' do
      it 'parses superscript' do
        body = get_section('superscript')

        aggregate_failures do
          expect(body.to_html).to match('1<sup>st</sup>')
          expect(body.to_html).to match('2<sup>nd</sup>')
        end
      end
    end
  end

  describe 'HTML::Pipeline' do
    describe 'SanitizationFilter' do
      it 'permits b elements' do
        expect(doc).to have_selector('b:contains("b tag")')
      end

      it 'permits em elements' do
        expect(doc).to have_selector('em:contains("em tag")')
      end

      it 'permits code elements' do
        expect(doc).to have_selector('code:contains("code tag")')
      end

      it 'permits kbd elements' do
        expect(doc).to have_selector('kbd:contains("s")')
      end

      it 'permits strike elements' do
        expect(doc).to have_selector('strike:contains(Emoji)')
      end

      it 'permits img elements' do
        expect(doc).to have_selector('img[src*="smile.png"]')
      end

      it 'permits br elements' do
        expect(doc).to have_selector('br')
      end

      it 'permits hr elements' do
        expect(doc).to have_selector('hr')
      end

      it 'permits span elements' do
        expect(doc).to have_selector('span:contains("span tag")')
      end

      it 'permits style attribute in th elements' do
        aggregate_failures do
          expect(doc.at_css('th:contains("Header")')['style']).to eq 'text-align: center'
          expect(doc.at_css('th:contains("Row")')['style']).to eq 'text-align: right'
          expect(doc.at_css('th:contains("Example")')['style']).to eq 'text-align: left'
        end
      end

      it 'permits style attribute in td elements' do
        aggregate_failures do
          expect(doc.at_css('td:contains("Foo")')['style']).to eq 'text-align: center'
          expect(doc.at_css('td:contains("Bar")')['style']).to eq 'text-align: right'
          expect(doc.at_css('td:contains("Baz")')['style']).to eq 'text-align: left'
        end
      end

      it 'removes `rel` attribute from links' do
        expect(doc).not_to have_selector('a[rel="bookmark"]')
      end

      it "removes `href` from `a` elements if it's fishy" do
        expect(doc).not_to have_selector('a[href*="javascript"]')
      end
    end

    describe 'Escaping' do
      it 'escapes non-tag angle brackets' do
        table = doc.css('table').last.at_css('tbody')
        expect(table.at_xpath('.//tr[1]/td[3]').inner_html).to eq '1 &lt; 3 &amp; 5'
      end
    end

    describe 'Edge Cases' do
      it 'allows markup inside link elements' do
        aggregate_failures do
          expect(doc.at_css('a[href="#link-emphasis"]').to_html).
            to eq %{<a href="#link-emphasis"><em>text</em></a>}

          expect(doc.at_css('a[href="#link-strong"]').to_html).
            to eq %{<a href="#link-strong"><strong>text</strong></a>}

          expect(doc.at_css('a[href="#link-code"]').to_html).
            to eq %{<a href="#link-code"><code>text</code></a>}
        end
      end
    end

    describe 'EmojiFilter' do
      it 'parses Emoji' do
        expect(doc).to have_selector('img.emoji', count: 10)
      end
    end

    describe 'TableOfContentsFilter' do
      it 'creates anchors inside header elements' do
        aggregate_failures do
          expect(doc).to have_selector('h1 a#gitlab-markdown')
          expect(doc).to have_selector('h2 a#markdown')
          expect(doc).to have_selector('h3 a#autolinkfilter')
        end
      end
    end

    describe 'AutolinkFilter' do
      def body
        get_section('autolinkfilter').next_element
      end

      # Override Capybara's `have_link` matcher to simplify our use case
      def have_link(link)
        super(link, href: link)
      end

      it 'autolinks http://' do
        expect(body).to have_link('http://about.gitlab.com/')
      end

      it 'autolinks https://' do
        expect(body).to have_link('https://google.com/')
      end

      it 'autolinks ftp://' do
        expect(body).to have_link('ftp://ftp.us.debian.org/debian/')
      end

      it 'autolinks smb://' do
        expect(body).to have_link('smb://foo/bar/baz')
      end

      it 'autolinks irc://' do
        expect(body).to have_link('irc://irc.freenode.net/git')
      end

      it 'autolinks short, invalid URLs' do
        expect(body).to have_link('http://localhost:3000')
      end

      %w(code a kbd).each do |elem|
        it "ignores links inside '#{elem}' element" do
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
        header = doc.at_css('#reference-filters-eg-1').parent

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

        aggregate_failures do
          expect(body).to have_selector('ul.task-list', count: 2)
          expect(body).to have_selector('li.task-list-item', count: 7)
          expect(body).to have_selector('input[checked]', count: 3)
        end
      end
    end
  end

  # `markdown` calls these two methods
  def current_user
    @feat.user
  end

  def user_color_scheme_class
    :white
  end
end
