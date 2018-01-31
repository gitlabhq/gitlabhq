require 'spec_helper'

describe 'Copy as GFM', :js do
  include MarkupHelper
  include RepoHelpers
  include ActionView::Helpers::JavaScriptHelper

  before do
    sign_in(create(:admin))
  end

  describe 'Copying rendered GFM' do
    before do
      @feat = MarkdownFeature.new

      # `markdown` helper expects a `@project` variable
      @project = @feat.project

      visit project_issue_path(@project, @feat.issue)
    end

    # The filters referenced in lib/banzai/pipeline/gfm_pipeline.rb convert GitLab Flavored Markdown (GFM) to HTML.
    # The handlers defined in app/assets/javascripts/copy_as_gfm.js consequently convert that same HTML to GFM.
    # To make sure these filters and handlers are properly aligned, this spec tests the GFM-to-HTML-to-GFM cycle
    # by verifying (`html_to_gfm(gfm_to_html(gfm)) == gfm`) for a number of examples of GFM for every filter, using the `verify` helper.

    # These are all in a single `it` for performance reasons.
    it 'works', :aggregate_failures do
      verify(
        'nesting',

        '> 1. [x] **[$`2 + 2`$ {-=-}{+=+} 2^2 ~~:thumbsup:~~](http://google.com)**'
      )

      verify(
        'a real world example from the gitlab-ce README',

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
      )

      aggregate_failures('an accidentally selected empty element') do
        gfm = '# Heading1'

        html = <<-HTML.strip_heredoc
          <h1>Heading1</h1>

          <h2></h2>
        HTML

        output_gfm = html_to_gfm(html)
        expect(output_gfm.strip).to eq(gfm.strip)
      end

      aggregate_failures('an accidentally selected other element') do
        gfm = 'Test comment with **Markdown!**'

        html = <<-HTML.strip_heredoc
          <li class="note">
            <div class="md">
              <p>
                Test comment with <strong>Markdown!</strong>
              </p>
            </div>
          </li>

          <li class="note"></li>
        HTML

        output_gfm = html_to_gfm(html)
        expect(output_gfm.strip).to eq(gfm.strip)
      end

      verify(
        'InlineDiffFilter',

        '{-Deleted text-}',
        '{+Added text+}'
      )

      verify(
        'TaskListFilter',

        '- [ ] Unchecked task',
        '- [x] Checked task',
        '1. [ ] Unchecked numbered task',
        '1. [x] Checked numbered task'
      )

      verify(
        'ReferenceFilter',

        # issue reference
        @feat.issue.to_reference,
        # full issue reference
        @feat.issue.to_reference(full: true),
        # issue URL
        project_issue_url(@project, @feat.issue),
        # issue URL with note anchor
        project_issue_url(@project, @feat.issue, anchor: 'note_123'),
        # issue link
        "[Issue](#{project_issue_url(@project, @feat.issue)})",
        # issue link with note anchor
        "[Issue](#{project_issue_url(@project, @feat.issue, anchor: 'note_123')})"
      )

      verify(
        'AutolinkFilter',

        'https://example.com'
      )

      verify(
        'TableOfContentsFilter',

        '[[_TOC_]]'
      )

      verify(
        'EmojiFilter',

        ':thumbsup:'
      )

      verify(
        'ImageLinkFilter',

        '![Image](https://example.com/image.png)'
      )

      verify(
        'VideoLinkFilter',

        '![Video](https://example.com/video.mp4)'
      )

      verify(
        'MathFilter: math as converted from GFM to HTML',

        '$`c = \pm\sqrt{a^2 + b^2}`$',

        # math block
        <<-GFM.strip_heredoc
          ```math
          c = \pm\sqrt{a^2 + b^2}
          ```
        GFM
      )

      aggregate_failures('MathFilter: math as transformed from HTML to KaTeX') do
        gfm = '$`c = \pm\sqrt{a^2 + b^2}`$'

        html = <<-HTML.strip_heredoc
          <span class="katex">
            <span class="katex-mathml">
              <math>
                <semantics>
                  <mrow>
                    <mi>c</mi>
                    <mo>=</mo>
                    <mo>±</mo>
                    <msqrt>
                      <mrow>
                        <msup>
                          <mi>a</mi>
                          <mn>2</mn>
                        </msup>
                        <mo>+</mo>
                        <msup>
                          <mi>b</mi>
                          <mn>2</mn>
                        </msup>
                      </mrow>
                    </msqrt>
                  </mrow>
                  <annotation encoding="application/x-tex">c = \\pm\\sqrt{a^2 + b^2}</annotation>
                </semantics>
              </math>
            </span>
            <span class="katex-html" aria-hidden="true">
                <span class="strut" style="height: 0.913389em;"></span>
                <span class="strut bottom" style="height: 1.04em; vertical-align: -0.126611em;"></span>
                <span class="base textstyle uncramped">
                  <span class="mord mathit">c</span>
                  <span class="mrel">=</span>
                  <span class="mord">±</span>
                  <span class="sqrt mord"><span class="sqrt-sign" style="top: -0.073389em;">
                    <span class="style-wrap reset-textstyle textstyle uncramped">√</span>
                  </span>
                  <span class="vlist">
                    <span class="" style="top: 0em;">
                      <span class="fontsize-ensurer reset-size5 size5">
                        <span class="" style="font-size: 1em;">​</span>
                      </span>
                      <span class="mord textstyle cramped">
                        <span class="mord">
                          <span class="mord mathit">a</span>
                          <span class="msupsub">
                            <span class="vlist">
                              <span class="" style="top: -0.289em; margin-right: 0.05em;">
                                <span class="fontsize-ensurer reset-size5 size5">
                                  <span class="" style="font-size: 0em;">​</span>
                                </span>
                                <span class="reset-textstyle scriptstyle cramped">
                                  <span class="mord mathrm">2</span>
                                </span>
                              </span>
                              <span class="baseline-fix">
                                <span class="fontsize-ensurer reset-size5 size5">
                                  <span class="" style="font-size: 0em;">​</span>
                                </span>
                              ​</span>
                            </span>
                          </span>
                        </span>
                        <span class="mbin">+</span>
                        <span class="mord">
                          <span class="mord mathit">b</span>
                          <span class="msupsub">
                            <span class="vlist">
                              <span class="" style="top: -0.289em; margin-right: 0.05em;">
                                <span class="fontsize-ensurer reset-size5 size5">
                                  <span class="" style="font-size: 0em;">​</span>
                                </span>
                                <span class="reset-textstyle scriptstyle cramped">
                                  <span class="mord mathrm">2</span>
                                </span>
                              </span>
                              <span class="baseline-fix">
                                <span class="fontsize-ensurer reset-size5 size5">
                                  <span class="" style="font-size: 0em;">​</span>
                                </span>
                              ​</span>
                            </span>
                          </span>
                        </span>
                      </span>
                    </span>
                    <span class="" style="top: -0.833389em;">
                      <span class="fontsize-ensurer reset-size5 size5">
                        <span class="" style="font-size: 1em;">​</span>
                      </span>
                      <span class="reset-textstyle textstyle uncramped sqrt-line"></span>
                    </span>
                    <span class="baseline-fix">
                      <span class="fontsize-ensurer reset-size5 size5">
                        <span class="" style="font-size: 1em;">​</span>
                      </span>
                    ​</span>
                  </span>
                </span>
              </span>
            </span>
          </span>
        HTML

        output_gfm = html_to_gfm(html)
        expect(output_gfm.strip).to eq(gfm.strip)
      end

      verify(
        'MermaidFilter: mermaid as converted from GFM to HTML',

        <<-GFM.strip_heredoc
          ```mermaid
          graph TD;
            A-->B;
          ```
        GFM
      )

      aggregate_failures('MermaidFilter: mermaid as transformed from HTML to SVG') do
        gfm = <<-GFM.strip_heredoc
          ```mermaid
          graph TD;
            A-->B;
          ```
        GFM

        html = <<-HTML.strip_heredoc
          <svg id="mermaidChart1" xmlns="http://www.w3.org/2000/svg" height="100%" viewBox="0 0 87.234375 174" style="max-width:87.234375px;" class="mermaid">
            <style>
              .mermaid {
                /* Flowchart variables */
                /* Sequence Diagram variables */
                /* Gantt chart variables */
                /** Section styling */
                /* Grid and axis */
                /* Today line */
                /* Task styling */
                /* Default task */
                /* Specific task settings for the sections*/
                /* Active task */
                /* Completed task */
                /* Tasks on the critical line */
              }
            </style>
            <g>
              <g class="output">
                <g class="clusters"></g>
                <g class="edgePaths">
                  <g class="edgePath" style="opacity: 1;">
                    <path class="path" d="M33.6171875,52L33.6171875,77L33.6171875,102" marker-end="url(#arrowhead65)" style="fill:none"></path>
                    <defs>
                      <marker id="arrowhead65" viewBox="0 0 10 10" refX="9" refY="5" markerUnits="strokeWidth" markerWidth="8" markerHeight="6" orient="auto">
                        <path d="M 0 0 L 10 5 L 0 10 z" class="arrowheadPath" style="stroke-width: 1; stroke-dasharray: 1, 0;"></path>
                      </marker>
                    </defs>
                  </g>
                </g>
                <g class="edgeLabels">
                  <g class="edgeLabel" style="opacity: 1;" transform="">
                    <g transform="translate(0,0)" class="label">
                      <foreignObject width="0" height="0">
                        <div xmlns="http://www.w3.org/1999/xhtml" style="display: inline-block; white-space: nowrap;">
                          <span class="edgeLabel"></span>
                        </div>
                      </foreignObject>
                    </g>
                  </g>
                </g>
                <g class="nodes">
                  <g class="node" id="A" transform="translate(33.6171875,36)" style="opacity: 1;">
                    <rect rx="0" ry="0" x="-13.6171875" y="-16" width="27.234375" height="32"></rect>
                    <g class="label" transform="translate(0,0)">
                      <g transform="translate(-3.6171875,-6)">
                        <foreignObject width="7.234375" height="12">
                          <div xmlns="http://www.w3.org/1999/xhtml" style="display: inline-block; white-space: nowrap;">A</div>
                        </foreignObject>
                      </g>
                    </g>
                  </g>
                  <g class="node" id="B" transform="translate(33.6171875,118)" style="opacity: 1;">
                    <rect rx="0" ry="0" x="-13.6171875" y="-16" width="27.234375" height="32">
                    </rect>
                    <g class="label" transform="translate(0,0)">
                      <g transform="translate(-3.6171875,-6)">
                        <foreignObject width="7.234375" height="12">
                          <div xmlns="http://www.w3.org/1999/xhtml" style="display: inline-block; white-space: nowrap;">B</div>
                        </foreignObject>
                      </g>
                    </g>
                  </g>
                </g>
              </g>
            </g>
            <text class="source" display="none">graph TD;
            A--&gt;B;
            </text>
          </svg>
        HTML

        output_gfm = html_to_gfm(html)
        expect(output_gfm.strip).to eq(gfm.strip)
      end

      verify(
        'SanitizationFilter',

        <<-GFM.strip_heredoc
        <sub>sub</sub>

        <dl>
          <dt>dt</dt>
          <dd>dd</dd>
        </dl>

        <kbd>kbd</kbd>

        <q>q</q>

        <samp>samp</samp>

        <var>var</var>

        <ruby>ruby</ruby>

        <rt>rt</rt>

        <rp>rp</rp>

        <abbr>abbr</abbr>

        <summary>summary</summary>

        <details>details</details>
        GFM
      )

      verify(
        'SanitizationFilter',

        <<-GFM.strip_heredoc,
          ```
          Plain text
          ```
        GFM

        <<-GFM.strip_heredoc,
          ```ruby
          def foo
            bar
          end
          ```
        GFM

        <<-GFM.strip_heredoc
          Foo

              This is an example of GFM

              ```js
              Code goes here
              ```
        GFM
      )

      verify(
        'MarkdownFilter',

        "Line with two spaces at the end  \nto insert a linebreak",

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

        # list with blockquote
        <<-GFM.strip_heredoc,
          - List

              > Blockquote
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
          |:--------:|------:|------|
          | Foo | Bar | **Baz** |
          | Foo | Bar | **Baz** |
        GFM

        # table with empty heading
        <<-GFM.strip_heredoc,
          |  | x | y |
          |---|---|---|
          | a | 1 | 0 |
          | b | 0 | 1 |
        GFM
      )
    end

    alias_method :gfm_to_html, :markdown

    def verify(label, *gfms)
      aggregate_failures(label) do
        gfms.each do |gfm|
          html = gfm_to_html(gfm).gsub(/\A&#x000A;|&#x000A;\z/, '')
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

  describe 'Copying code' do
    let(:project) { create(:project, :repository) }

    context 'from a diff' do
      shared_examples 'copying code from a diff' do
        context 'selecting one word of text' do
          it 'copies as inline code' do
            verify(
              '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"] .line .no',

              '`RuntimeError`',

              target: '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"]'
            )
          end
        end

        context 'selecting one line of text' do
          it 'copies as inline code' do
            verify(
              '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"]',

              '`raise RuntimeError, "System commands must be given as an array of strings"`',

              target: '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"]'
            )
          end
        end

        context 'selecting multiple lines of text' do
          it 'copies as a code block' do
            verify(
              '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_10"]',

              <<-GFM.strip_heredoc,
                ```ruby
                      raise RuntimeError, "System commands must be given as an array of strings"
                    end
                ```
              GFM

              target: '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"]'
            )
          end
        end
      end

      context 'inline diff' do
        before do
          visit project_commit_path(project, sample_commit.id, view: 'inline')
        end

        it_behaves_like 'copying code from a diff'
      end

      context 'parallel diff' do
        before do
          visit project_commit_path(project, sample_commit.id, view: 'parallel')
        end

        it_behaves_like 'copying code from a diff'

        context 'selecting code on the left' do
          it 'copies as a code block' do
            verify(
              '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_8_8"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_9_9"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_10"]',

              <<-GFM.strip_heredoc,
                ```ruby
                    unless cmd.is_a?(Array)
                      raise "System commands must be given as an array of strings"
                    end
                ```
              GFM

              target: '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_8_8"].left-side'
            )
          end
        end

        context 'selecting code on the right' do
          it 'copies as a code block' do
            verify(
              '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_8_8"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_9_9"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_10"]',

              <<-GFM.strip_heredoc,
                ```ruby
                    unless cmd.is_a?(Array)
                      raise RuntimeError, "System commands must be given as an array of strings"
                    end
                ```
              GFM

              target: '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_8_8"].right-side'
            )
          end
        end
      end
    end

    context 'from a blob' do
      before do
        visit project_blob_path(project, File.join('master', 'files/ruby/popen.rb'))
        wait_for_requests
      end

      context 'selecting one word of text' do
        it 'copies as inline code' do
          verify(
            '.line[id="LC9"] .no',

            '`RuntimeError`'
          )
        end
      end

      context 'selecting one line of text' do
        it 'copies as inline code' do
          verify(
            '.line[id="LC9"]',

            '`raise RuntimeError, "System commands must be given as an array of strings"`'
          )
        end
      end

      context 'selecting multiple lines of text' do
        it 'copies as a code block' do
          verify(
            '.line[id="LC9"], .line[id="LC10"]',

            <<-GFM.strip_heredoc,
              ```ruby
                    raise RuntimeError, "System commands must be given as an array of strings"
                  end
              ```
            GFM
          )
        end
      end
    end

    context 'from a GFM code block' do
      before do
        visit project_blob_path(project, File.join('markdown', 'doc/api/users.md'))
        wait_for_requests
      end

      context 'selecting one word of text' do
        it 'copies as inline code' do
          verify(
            '.line[id="LC27"] .s2',

            '`"bio"`'
          )
        end
      end

      context 'selecting one line of text' do
        it 'copies as inline code' do
          verify(
            '.line[id="LC27"]',

            '`"bio": null,`'
          )
        end
      end

      context 'selecting multiple lines of text' do
        it 'copies as a code block with the correct language' do
          verify(
            '.line[id="LC27"], .line[id="LC28"]',

            <<-GFM.strip_heredoc,
              ```json
                  "bio": null,
                  "skype": "",
              ```
            GFM
          )
        end
      end
    end

    def verify(selector, gfm, target: nil)
      html = html_for_selector(selector)
      output_gfm = html_to_gfm(html, 'transformCodeSelection', target: target)
      expect(output_gfm.strip).to eq(gfm.strip)
    end
  end

  def html_for_selector(selector)
    js = <<-JS.strip_heredoc
      (function(selector) {
        var els = document.querySelectorAll(selector);
        var htmls = _.map(els, function(el) { return el.outerHTML; });
        return htmls.join("\\n");
      })("#{escape_javascript(selector)}")
    JS
    page.evaluate_script(js)
  end

  def html_to_gfm(html, transformer = 'transformGFMSelection', target: nil)
    js = <<-JS.strip_heredoc
      (function(html) {
        var transformer = window.CopyAsGFM[#{transformer.inspect}];

        var node = document.createElement('div');
        $(html).each(function() { node.appendChild(this) });

        var targetSelector = #{target.to_json};
        var target;
        if (targetSelector) {
          target = document.querySelector(targetSelector);
        }

        node = transformer(node, target);
        if (!node) return null;

        return window.CopyAsGFM.nodeToGFM(node);
      })("#{escape_javascript(html)}")
    JS
    page.evaluate_script(js)
  end
end
