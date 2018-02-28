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
#         -> `gfm` helper
#           -> HTML::Pipeline
#             -> SanitizationFilter
#             -> Other filters, depending on pipeline
#           -> `html_safe`
#           -> Template
#
# See the MarkdownFeature class for setup details.

describe 'GitLab Markdown' do
  include Capybara::Node::Matchers
  include MarkupHelper
  include MarkdownMatchers

  # Sometimes it can be useful to see the parsed output of the Markdown document
  # for debugging. Call this method to write the output to
  # `tmp/capybara/<filename>.html`.
  def write_markdown(filename = 'markdown_spec')
    File.open(Rails.root.join("tmp/capybara/#{filename}.html"), 'w') do |file|
      file.puts @html
    end
  end

  def doc(html = @html)
    @doc ||= Nokogiri::HTML::DocumentFragment.parse(html)
  end

  # Shared behavior that all pipelines should exhibit
  shared_examples 'all pipelines' do
    describe 'Redcarpet extensions' do
      it 'does not parse emphasis inside of words' do
        expect(doc.to_html).not_to match('foo<em>bar</em>baz')
      end

      it 'parses table Markdown' do
        aggregate_failures do
          expect(doc).to have_selector('th:contains("Header")')
          expect(doc).to have_selector('th:contains("Row")')
          expect(doc).to have_selector('th:contains("Example")')
        end
      end

      it 'allows Markdown in tables' do
        expect(doc.at_css('td:contains("Baz")').children.to_html)
          .to eq '<strong>Baz</strong>'
      end

      it 'parses fenced code blocks' do
        aggregate_failures do
          expect(doc).to have_selector('pre.code.highlight.js-syntax-highlight.c')
          expect(doc).to have_selector('pre.code.highlight.js-syntax-highlight.python')
        end
      end

      it 'parses mermaid code block' do
        aggregate_failures do
          expect(doc).to have_selector('pre.code.js-render-mermaid')
        end
      end

      it 'parses strikethroughs' do
        expect(doc).to have_selector(%{del:contains("and this text doesn't")})
      end

      it 'parses superscript' do
        expect(doc).to have_selector('sup', count: 2)
      end
    end

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
        expect(doc).to have_selector('img[data-src*="smile.png"]')
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

      it 'permits details elements' do
        expect(doc).to have_selector('details:contains("Hiding the details")')
      end

      it 'permits summary elements' do
        expect(doc).to have_selector('details summary:contains("collapsible")')
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
          expect(doc.at_css('a[href="#link-emphasis"]').to_html)
            .to eq %{<a href="#link-emphasis"><em>text</em></a>}

          expect(doc.at_css('a[href="#link-strong"]').to_html)
            .to eq %{<a href="#link-strong"><strong>text</strong></a>}

          expect(doc.at_css('a[href="#link-code"]').to_html)
            .to eq %{<a href="#link-code"><code>text</code></a>}
        end
      end
    end

    describe 'ExternalLinkFilter' do
      it 'adds nofollow to external link' do
        link = doc.at_css('a:contains("Google")')

        expect(link.attr('rel')).to include('nofollow')
      end

      it 'adds noreferrer to external link' do
        link = doc.at_css('a:contains("Google")')

        expect(link.attr('rel')).to include('noreferrer')
      end

      it 'adds _blank to target attribute for external links' do
        link = doc.at_css('a:contains("Google")')

        expect(link.attr('target')).to match('_blank')
      end

      it 'ignores internal link' do
        link = doc.at_css('a:contains("GitLab Root")')

        expect(link.attr('rel')).not_to match 'nofollow'
        expect(link.attr('target')).not_to match '_blank'
      end
    end
  end

  before do
    @feat = MarkdownFeature.new

    # `markdown` helper expects a `@project` and `@group` variable
    @project = @feat.project
    @group = @feat.group
  end

  context 'default pipeline' do
    before do
      @html = markdown(@feat.raw_markdown)
    end

    it_behaves_like 'all pipelines'

    it 'includes RelativeLinkFilter' do
      expect(doc).to parse_relative_links
    end

    it 'includes EmojiFilter' do
      expect(doc).to parse_emoji
    end

    it 'includes TableOfContentsFilter' do
      expect(doc).to create_header_links
    end

    it 'includes AutolinkFilter' do
      expect(doc).to create_autolinks
    end

    it 'includes all reference filters' do
      aggregate_failures do
        expect(doc).to reference_users
        expect(doc).to reference_issues
        expect(doc).to reference_merge_requests
        expect(doc).to reference_snippets
        expect(doc).to reference_commit_ranges
        expect(doc).to reference_commits
        expect(doc).to reference_labels
        expect(doc).to reference_milestones
      end
    end

    it 'includes TaskListFilter' do
      expect(doc).to parse_task_lists
    end

    it 'includes InlineDiffFilter' do
      expect(doc).to parse_inline_diffs
    end

    it 'includes VideoLinkFilter' do
      expect(doc).to parse_video_links
    end
  end

  context 'wiki pipeline' do
    before do
      @project_wiki = @feat.project_wiki
      @project_wiki_page = @feat.project_wiki_page

      file = Gollum::File.new(@project_wiki.wiki)
      expect(file).to receive(:path).and_return('images/example.jpg')
      expect(@project_wiki).to receive(:find_file).with('images/example.jpg').and_return(file)
      allow(@project_wiki).to receive(:wiki_base_path) { '/namespace1/gitlabhq/wikis' }

      @html = markdown(@feat.raw_markdown, { pipeline: :wiki, project_wiki: @project_wiki, page_slug: @project_wiki_page.slug })
    end

    it_behaves_like 'all pipelines'

    it 'includes RelativeLinkFilter' do
      expect(doc).not_to parse_relative_links
    end

    it 'includes EmojiFilter' do
      expect(doc).to parse_emoji
    end

    it 'includes TableOfContentsFilter' do
      expect(doc).to create_header_links
    end

    it 'includes AutolinkFilter' do
      expect(doc).to create_autolinks
    end

    it 'includes all reference filters' do
      aggregate_failures do
        expect(doc).to reference_users
        expect(doc).to reference_issues
        expect(doc).to reference_merge_requests
        expect(doc).to reference_snippets
        expect(doc).to reference_commit_ranges
        expect(doc).to reference_commits
        expect(doc).to reference_labels
        expect(doc).to reference_milestones
      end
    end

    it 'includes TaskListFilter' do
      expect(doc).to parse_task_lists
    end

    it 'includes GollumTagsFilter' do
      expect(doc).to parse_gollum_tags
    end

    it 'includes InlineDiffFilter' do
      expect(doc).to parse_inline_diffs
    end

    it 'includes VideoLinkFilter' do
      expect(doc).to parse_video_links
    end
  end

  # Fake a `current_user` helper
  def current_user
    @feat.user
  end
end
