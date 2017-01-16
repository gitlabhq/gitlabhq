require 'spec_helper'

describe 'Copy as GFM', feature: true, js: true do
  include GitlabMarkdownHelper
  include ActionView::Helpers::JavaScriptHelper

  before do
    @feat = MarkdownFeature.new

    # `markdown` helper expects a `@project` variable
    @project = @feat.project

    visit namespace_project_issue_path(@project.namespace, @project, @feat.issue)
  end

  # The filters referenced in lib/banzai/pipeline/gfm_pipeline.rb convert GitLab Flavored Markdown (GFM) to HTML.
  # The handlers defined in app/assets/javascripts/copy_as_gfm.js.es6 consequently convert that same HTML to GFM.
  # To make sure these filters and handlers are properly aligned, this spec tests the GFM-to-HTML-to-GFM cycle
  # by verifying (`html_to_gfm(gfm_to_html(gfm)) == gfm`) for a number of examples of GFM for every filter.

  it 'supports nesting' do
    verify '> 1. [x] **[$`2 + 2`$ {-=-}{+=+} 2^2 ~~:thumbsup:~~](http://google.com)**'
  end

  it 'supports a real world example from the gitlab-ce README' do
    verify <<-GFM.strip_heredoc
      # GitLab

      [![Build status](https://gitlab.com/gitlab-org/gitlab-ce/badges/master/build.svg)](https://gitlab.com/gitlab-org/gitlab-ce/commits/master)
      [![CE coverage report](https://gitlab.com/gitlab-org/gitlab-ce/badges/master/coverage.svg?job=coverage)](https://gitlab-org.gitlab.io/gitlab-ce/coverage-ruby)
      [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.svg)](https://codeclimate.com/github/gitlabhq/gitlabhq)
      [![Core Infrastructure Initiative Best Practices](https://bestpractices.coreinfrastructure.org/projects/42/badge)](https://bestpractices.coreinfrastructure.org/projects/42)

      ## Canonical source

      The canonical source of GitLab Community Edition is [hosted on GitLab.com](https://gitlab.com/gitlab-org/gitlab-ce/).

      ## Open source software to collaborate on code

      To see how GitLab looks please see the [features page on our website](https://about.gitlab.com/features/).


      - Manage Git repositories with fine grained access controls that keep your code secure

      - Perform code reviews and enhance collaboration with merge requests

      - Complete continuous integration (CI) and CD pipelines to builds, test, and deploy your applications

      - Each project can also have an issue tracker, issue board, and a wiki

      - Used by more than 100,000 organizations, GitLab is the most popular solution to manage Git repositories on-premises

      - Completely free and open source (MIT Expat license)
    GFM
  end

  it 'supports InlineDiffFilter' do
    verify(
      '{-Deleted text-}',
      '{+Added text+}'
    )
  end

  it 'supports TaskListFilter' do
    verify(
      '- [ ] Unchecked task',
      '- [x] Checked task',
      '1. [ ] Unchecked numbered task',
      '1. [x] Checked numbered task'
    )
  end

  it 'supports ReferenceFilter' do
    verify(
      # issue reference
      @feat.issue.to_reference,
      # full issue reference
      @feat.issue.to_reference(full: true),
      # issue URL
      namespace_project_issue_url(@project.namespace, @project, @feat.issue),
      # issue URL with note anchor
      namespace_project_issue_url(@project.namespace, @project, @feat.issue, anchor: 'note_123'),
      # issue link
      "[Issue](#{namespace_project_issue_url(@project.namespace, @project, @feat.issue)})",
      # issue link with note anchor
      "[Issue](#{namespace_project_issue_url(@project.namespace, @project, @feat.issue, anchor: 'note_123')})",
    )
  end

  it 'supports AutolinkFilter' do
    verify 'https://example.com'
  end

  it 'supports TableOfContentsFilter' do
    verify '[[_TOC_]]'
  end

  it 'supports EmojiFilter' do
    verify ':thumbsup:'
  end

  it 'supports ImageLinkFilter' do
    verify '![Image](https://example.com/image.png)'
  end

  it 'supports VideoLinkFilter' do
    verify '![Video](https://example.com/video.mp4)'
  end

  it 'supports MathFilter' do
    verify(
      '$`c = \pm\sqrt{a^2 + b^2}`$',
      # math block
      <<-GFM.strip_heredoc
        ```math
        c = \pm\sqrt{a^2 + b^2}
        ```
      GFM
    )
  end

  it 'supports SyntaxHighlightFilter' do
    verify <<-GFM.strip_heredoc
      ```ruby
      def foo
        bar
      end
      ```
    GFM
  end

  it 'supports MarkdownFilter' do
    verify(
      '`code`',
      '`` code with ` ticks ``',

      '> Quote',
      # multiline quote
      <<-GFM.strip_heredoc,
        > Multiline
        > Quote
        >
        > With multiple paragraphs
      GFM

      '![Image](https://example.com/image.png)',

      '# Heading with no anchor link',

      '[Link](https://example.com)',

      '- List item',

      # multiline list item
      <<-GFM.strip_heredoc,
        - Multiline
          List item
      GFM

      # nested lists
      <<-GFM.strip_heredoc,
        - Nested


          - Lists
      GFM

      '1. Numbered list item',

      # multiline numbered list item
      <<-GFM.strip_heredoc,
        1. Multiline
          Numbered list item
      GFM

      # nested numbered list
      <<-GFM.strip_heredoc,
        1. Nested


          1. Numbered lists
      GFM

      '# Heading',
      '## Heading',
      '### Heading',
      '#### Heading',
      '##### Heading',
      '###### Heading',

      '**Bold**',

      '_Italics_',

      '~~Strikethrough~~',

      '2^2',

      '-----',

      # table
      <<-GFM.strip_heredoc,
        | Centered | Right | Left |
        | :------: | ----: | ---- |
        | Foo | Bar | **Baz** |
        | Foo | Bar | **Baz** |
      GFM
    )
  end

  alias_method :gfm_to_html, :markdown

  def html_to_gfm(html)
    js = <<-JS.strip_heredoc
      (function(html) {
        var node = document.createElement('div');
        node.innerHTML = html;
        return window.gl.CopyAsGFM.nodeToGFM(node);
      })("#{escape_javascript(html)}")
    JS
    page.evaluate_script(js)
  end

  def verify(*gfms)
    aggregate_failures do
      gfms.each do |gfm|
        html = gfm_to_html(gfm)
        output_gfm = html_to_gfm(html)
        expect(output_gfm.strip).to eq(gfm.strip)
      end
    end
  end

  # Fake a `current_user` helper
  def current_user
    @feat.user
  end
end
