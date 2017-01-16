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

  # Should have an entry for every filter in lib/banzai/pipeline/gfm_pipeline.rb
  # and app/assets/javascripts/copy_as_gfm.js.es6
  filters = {
    'any filter' => [
      [
        'crazy nesting',
        '> 1. [x] **[$`2 + 2`$ {-=-}{+=+} 2^2 ~~:thumbsup:~~](http://google.com)**'
      ],
      [
        'real world example from the gitlab-ce README',
        <<-GFM.strip_heredoc
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
      ]
    ],
    'InlineDiffFilter' => [
      '{-Deleted text-}',
      '{+Added text+}'
    ],
    'TaskListFilter' => [
      '- [ ] Unchecked task',
      '- [x] Checked task',
      '1. [ ] Unchecked numbered task',
      '1. [x] Checked numbered task'
    ],
    'ReferenceFilter' => [
      ['issue reference', -> { @feat.issue.to_reference }],
      ['full issue reference', -> { @feat.issue.to_reference(full: true) }],
      ['issue URL', -> { namespace_project_issue_url(@project.namespace, @project, @feat.issue) }],
      ['issue URL with note anchor', -> { namespace_project_issue_url(@project.namespace, @project, @feat.issue, anchor: 'note_123') }],
      ['issue link', -> { "[Issue](#{namespace_project_issue_url(@project.namespace, @project, @feat.issue)})" }],
      ['issue link with note anchor', -> { "[Issue](#{namespace_project_issue_url(@project.namespace, @project, @feat.issue, anchor: 'note_123')})" }],
    ],
    'AutolinkFilter' => [
      'https://example.com'
    ],
    'TableOfContentsFilter' => [
      '[[_TOC_]]'
    ],
    'EmojiFilter' => [
      ':thumbsup:'
    ],
    'ImageLinkFilter' => [
      '![Image](https://example.com/image.png)'
    ],
    'VideoLinkFilter' => [
      '![Video](https://example.com/video.mp4)'
    ],
    'MathFilter' => [
      '$`c = \pm\sqrt{a^2 + b^2}`$',
      [
        'math block',
        <<-GFM.strip_heredoc
          ```math
          c = \pm\sqrt{a^2 + b^2}
          ```
        GFM
      ]
    ],
    'SyntaxHighlightFilter' => [
      [
        'code block',
        <<-GFM.strip_heredoc
          ```ruby
          def foo
            bar
          end
          ```
        GFM
      ]
    ],
    'MarkdownFilter' => [
      '`code`',
      '`` code with ` ticks ``',

      '> Quote',
      [
        'multiline quote',
        <<-GFM.strip_heredoc,
          > Multiline
          > Quote
          >
          > With multiple paragraphs
        GFM
      ],

      '![Image](https://example.com/image.png)',

      '# Heading with no anchor link',

      '[Link](https://example.com)',

      '- List item',
      [
        'multiline list item',
        <<-GFM.strip_heredoc,
          - Multiline
            List item
        GFM
      ],
      [
        'nested lists',
        <<-GFM.strip_heredoc,
          - Nested


            - Lists
        GFM
      ],
      '1. Numbered list item',
      [
        'multiline numbered list item',
        <<-GFM.strip_heredoc,
          1. Multiline
            Numbered list item
        GFM
      ],
      [
        'nested numbered list',
        <<-GFM.strip_heredoc,
          1. Nested


            1. Numbered lists
        GFM
      ],

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

      [
        'table',
        <<-GFM.strip_heredoc,
          | Centered | Right | Left |
          | :------: | ----: | ---- |
          | Foo | Bar | **Baz** |
          | Foo | Bar | **Baz** |
        GFM
      ]
    ]
  }

  filters.each do |filter, examples|
    context filter do
      examples.each do |ex|
        if ex.is_a?(String)
          desc = "'#{ex}'"
          gfm = ex
        else
          desc, gfm = ex
        end

        it "transforms #{desc} to HTML and back to GFM" do
          gfm = instance_exec(&gfm) if gfm.is_a?(Proc)

          html = markdown(gfm)
          gfm2 = html_to_gfm(html)
          expect(gfm2.strip).to eq(gfm.strip)
        end
      end
    end
  end

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

  # Fake a `current_user` helper
  def current_user
    @feat.user
  end
end
