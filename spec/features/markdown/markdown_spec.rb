# frozen_string_literal: true

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
#     -> CommonMark::Render::GitlabHTML converts Markdown to HTML
#       -> Post-process HTML
#         -> `gfm` helper
#           -> HTML::Pipeline
#             -> SanitizationFilter
#             -> Other filters, depending on pipeline
#           -> `html_safe`
#           -> Template
#
# See the MarkdownFeature class for setup details.

RSpec.describe 'GitLab Markdown', :aggregate_failures do
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
    it 'includes extensions' do
      aggregate_failures 'does not parse emphasis inside of words' do
        expect(doc.to_html).not_to match('foo<em>bar</em>baz')
      end

      aggregate_failures 'parses table Markdown' do
        expect(doc).to have_selector('th:contains("Header")')
        expect(doc).to have_selector('th:contains("Row")')
        expect(doc).to have_selector('th:contains("Example")')
      end

      aggregate_failures 'allows Markdown in tables' do
        expect(doc.at_css('td:contains("Baz")').children.to_html)
          .to eq '<strong>Baz</strong>'
      end

      aggregate_failures 'parses fenced code blocks' do
        expect(doc).to have_selector('pre.code.highlight.js-syntax-highlight.language-c')
        expect(doc).to have_selector('pre.code.highlight.js-syntax-highlight.language-python')
      end

      aggregate_failures 'parses mermaid code block' do
        expect(doc).to have_selector('pre[lang=mermaid] > code.js-render-mermaid')
      end

      aggregate_failures 'parses strikethroughs' do
        expect(doc).to have_selector(%{del:contains("and this text doesn't")})
      end
    end

    it 'includes SanitizationFilter' do
      aggregate_failures 'permits b elements' do
        expect(doc).to have_selector('b:contains("b tag")')
      end

      aggregate_failures 'permits em elements' do
        expect(doc).to have_selector('em:contains("em tag")')
      end

      aggregate_failures 'permits code elements' do
        expect(doc).to have_selector('code:contains("code tag")')
      end

      aggregate_failures 'permits kbd elements' do
        expect(doc).to have_selector('kbd:contains("s")')
      end

      aggregate_failures 'permits strike elements' do
        expect(doc).to have_selector('strike:contains(Emoji)')
      end

      aggregate_failures 'permits img elements' do
        expect(doc).to have_selector('img[data-src*="smile.png"]')
      end

      aggregate_failures 'permits br elements' do
        expect(doc).to have_selector('br')
      end

      aggregate_failures 'permits hr elements' do
        expect(doc).to have_selector('hr')
      end

      aggregate_failures 'permits span elements' do
        expect(doc).to have_selector('span:contains("span tag")')
      end

      aggregate_failures 'permits details elements' do
        expect(doc).to have_selector('details:contains("Hiding the details")')
      end

      aggregate_failures 'permits summary elements' do
        expect(doc).to have_selector('details summary:contains("collapsible")')
      end

      aggregate_failures 'permits align attribute in th elements' do
        expect(doc.at_css('th:contains("Header")')['align']).to eq 'center'
        expect(doc.at_css('th:contains("Row")')['align']).to eq 'right'
        expect(doc.at_css('th:contains("Example")')['align']).to eq 'left'
      end

      aggregate_failures 'permits align attribute in td elements' do
        expect(doc.at_css('td:contains("Foo")')['align']).to eq 'center'
        expect(doc.at_css('td:contains("Bar")')['align']).to eq 'right'
        expect(doc.at_css('td:contains("Baz")')['align']).to eq 'left'
      end

      aggregate_failures 'permits superscript elements' do
        expect(doc).to have_selector('sup', count: 2)
      end

      aggregate_failures 'permits subscript elements' do
        expect(doc).to have_selector('sub', count: 3)
      end

      aggregate_failures 'removes `rel` attribute from links' do
        expect(doc).not_to have_selector('a[rel="bookmark"]')
      end

      aggregate_failures "removes `href` from `a` elements if it's fishy" do
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

    it 'includes ExternalLinkFilter' do
      aggregate_failures 'adds nofollow to external link' do
        link = doc.at_css('a:contains("Google")')

        expect(link.attr('rel')).to include('nofollow')
      end

      aggregate_failures 'adds noreferrer to external link' do
        link = doc.at_css('a:contains("Google")')

        expect(link.attr('rel')).to include('noreferrer')
      end

      aggregate_failures 'adds _blank to target attribute for external links' do
        link = doc.at_css('a:contains("Google")')

        expect(link.attr('target')).to match('_blank')
      end

      aggregate_failures 'ignores internal link' do
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

    stub_application_setting(plantuml_enabled: true, plantuml_url: 'http://localhost:8080')
    stub_application_setting(kroki_enabled: true, kroki_url: 'http://localhost:8000')
  end

  let(:project) { @feat.project } # Shadow this so matchers can use it

  context 'default pipeline' do
    before do
      @html = markdown(@feat.raw_markdown)
    end

    it_behaves_like 'all pipelines'

    it 'includes custom filters' do
      aggregate_failures 'UploadLinkFilter' do
        expect(doc).to parse_upload_links
      end

      aggregate_failures 'RepositoryLinkFilter' do
        expect(doc).to parse_repository_links
      end

      aggregate_failures 'EmojiFilter' do
        expect(doc).to parse_emoji
      end

      aggregate_failures 'TableOfContentsFilter' do
        expect(doc).to create_header_links
      end

      aggregate_failures 'AutolinkFilter' do
        expect(doc).to create_autolinks
      end

      aggregate_failures 'all reference filters' do
        expect(doc).to reference_users
        expect(doc).to reference_issues
        expect(doc).to reference_merge_requests
        expect(doc).to reference_snippets
        expect(doc).to reference_commit_ranges
        expect(doc).to reference_commits
        expect(doc).to reference_labels
        expect(doc).to reference_milestones
        expect(doc).to reference_alerts
      end

      aggregate_failures 'TaskListFilter' do
        expect(doc).to parse_task_lists
      end

      aggregate_failures 'InlineDiffFilter' do
        expect(doc).to parse_inline_diffs
      end

      aggregate_failures 'VideoLinkFilter' do
        expect(doc).to parse_video_links
      end

      aggregate_failures 'ColorFilter' do
        expect(doc).to parse_colors
      end

      aggregate_failures 'MermaidFilter' do
        expect(doc).to parse_mermaid
      end

      aggregate_failures 'PlantumlFilter' do
        expect(doc).to parse_plantuml
      end

      aggregate_failures 'KrokiFilter' do
        expect(doc).to parse_kroki
      end
    end
  end

  context 'wiki pipeline' do
    before do
      @wiki = @feat.wiki
      @wiki_page = @feat.wiki_page

      name = 'example.jpg'
      path = "images/#{name}"
      blob = double(name: name, path: path, mime_type: 'image/jpeg', data: nil)
      expect(@wiki).to receive(:find_file).with(path, load_content: false).and_return(Gitlab::Git::WikiFile.new(blob))
      allow(@wiki).to receive(:wiki_base_path) { '/namespace1/gitlabhq/wikis' }

      @html = markdown(@feat.raw_markdown, { pipeline: :wiki, wiki: @wiki, page_slug: @wiki_page.slug })
    end

    it_behaves_like 'all pipelines'

    it 'includes custom filters' do
      aggregate_failures 'UploadLinkFilter' do
        expect(doc).to parse_upload_links
      end

      aggregate_failures 'RepositoryLinkFilter' do
        expect(doc).not_to parse_repository_links
      end

      aggregate_failures 'EmojiFilter' do
        expect(doc).to parse_emoji
      end

      aggregate_failures 'TableOfContentsFilter' do
        expect(doc).to create_header_links
      end

      aggregate_failures 'AutolinkFilter' do
        expect(doc).to create_autolinks
      end

      aggregate_failures 'all reference filters' do
        expect(doc).to reference_users
        expect(doc).to reference_issues
        expect(doc).to reference_merge_requests
        expect(doc).to reference_snippets
        expect(doc).to reference_commit_ranges
        expect(doc).to reference_commits
        expect(doc).to reference_labels
        expect(doc).to reference_milestones
      end

      aggregate_failures 'TaskListFilter' do
        expect(doc).to parse_task_lists
      end

      aggregate_failures 'GollumTagsFilter' do
        expect(doc).to parse_gollum_tags
      end

      aggregate_failures 'InlineDiffFilter' do
        expect(doc).to parse_inline_diffs
      end

      aggregate_failures 'VideoLinkFilter' do
        expect(doc).to parse_video_links
      end

      aggregate_failures 'AudioLinkFilter' do
        expect(doc).to parse_audio_links
      end

      aggregate_failures 'ColorFilter' do
        expect(doc).to parse_colors
      end

      aggregate_failures 'MermaidFilter' do
        expect(doc).to parse_mermaid
      end

      aggregate_failures 'PlantumlFilter' do
        expect(doc).to parse_plantuml
      end

      aggregate_failures 'KrokiFilter' do
        expect(doc).to parse_kroki
      end
    end
  end

  # Fake a `current_user` helper
  def current_user
    @feat.user
  end
end
