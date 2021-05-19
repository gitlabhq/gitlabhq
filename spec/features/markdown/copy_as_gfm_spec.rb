# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Copy as GFM', :js do
  include MarkupHelper
  include RepoHelpers
  include ActionView::Helpers::JavaScriptHelper

  describe 'Copying rendered GFM' do
    before do
      @feat = MarkdownFeature.new

      # `markdown` helper expects a `@project` variable
      @project = @feat.project

      user = create(:user)
      @project.add_maintainer(user)
      sign_in(user)
      visit project_issue_path(@project, @feat.issue)
    end

    # The filters referenced in lib/banzai/pipeline/gfm_pipeline.rb transform GitLab Flavored Markdown (GFM) to HTML.
    # The nodes and marks referenced in app/assets/javascripts/behaviors/markdown/editor_extensions.js consequently transform that same HTML to GFM.
    # To make sure these filters and nodes/marks are properly aligned, this spec tests the GFM-to-HTML-to-GFM cycle
    # by verifying (`html_to_gfm(gfm_to_html(gfm)) == gfm`) for a number of examples of GFM for every filter, using the `verify` helper.

    # These are all in a single `it` for performance reasons.
    it 'works', :aggregate_failures do
      verify(
        'nesting',
        '> 1. [x] **[$`2 + 2`$ {-=-}{+=+} 2^2 ~~:thumbsup:~~](http://google.com)**'
      )

      verify(
        'a real world example from the gitlab-ce README',
        <<~GFM
          # GitLab

          [![Build status](https://gitlab.com/gitlab-org/gitlab-foss/badges/master/build.svg)](https://gitlab.com/gitlab-org/gitlab-foss/commits/master)

          [![CE coverage report](https://gitlab.com/gitlab-org/gitlab-foss/badges/master/coverage.svg?job=coverage)](https://gitlab-org.gitlab.io/gitlab-ce/coverage-ruby)

          [![Code Climate](https://codeclimate.com/github/gitlabhq/gitlabhq.svg)](https://codeclimate.com/github/gitlabhq/gitlabhq)

          [![Core Infrastructure Initiative Best Practices](https://bestpractices.coreinfrastructure.org/projects/42/badge)](https://bestpractices.coreinfrastructure.org/projects/42)

          ## Canonical source

          The canonical source of GitLab Community Edition is [hosted on GitLab.com](https://gitlab.com/gitlab-org/gitlab-foss/).

          ## Open source software to collaborate on code

          To see how GitLab looks please see the [features page on our website](https://about.gitlab.com/features/).

          * Manage Git repositories with fine grained access controls that keep your code secure
          * Perform code reviews and enhance collaboration with merge requests
          * Complete continuous integration (CI) and CD pipelines to builds, test, and deploy your applications
          * Each project can also have an issue tracker, issue board, and a wiki
          * Used by more than 100,000 organizations, GitLab is the most popular solution to manage Git repositories on-premises
          * Completely free and open source (MIT Expat license)
        GFM
      )

      aggregate_failures('an accidentally selected empty element') do
        gfm = '# Heading1'

        html = <<~HTML
          <h1>Heading1</h1>

          <h2></h2>

          <blockquote></blockquote>

          <pre class="code highlight"></pre>
        HTML

        output_gfm = html_to_gfm(html)
        expect(output_gfm.strip).to eq(gfm.strip)
      end

      aggregate_failures('an accidentally selected other element') do
        gfm = 'Test comment with **Markdown!**'

        html = <<~HTML
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
        <<~GFM,
          * [ ] Unchecked task
          * [x] Checked task
        GFM
        <<~GFM
          1. [ ] Unchecked ordered task
          1. [x] Checked ordered task
        GFM
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
        <<~GFM,
          [[_TOC_]]

          # Heading 1

          ## Heading 2
        GFM
        pipeline: :wiki,
        wiki: @project.wiki
      )

      verify(
        'EmojiFilter',
        ':thumbsup:'
      )

      verify(
        'ImageLinkFilter',
        '![Image](https://example.com/image.png)'
      )

      verify_media_with_partial_path(
        '[test.txt](/uploads/a123/image.txt)',
        project_media_uri(@project, '/uploads/a123/image.txt')
      )

      verify_media_with_partial_path(
        '![Image](/uploads/a123/image.png)',
        project_media_uri(@project, '/uploads/a123/image.png')
      )

      verify(
        'VideoLinkFilter',
        '![Video](https://example.com/video.mp4)'
      )

      verify_media_with_partial_path(
        '![Video](/uploads/a123/video.mp4)',
        project_media_uri(@project, '/uploads/a123/video.mp4')
      )

      verify(
        'AudioLinkFilter',
        '![Audio](https://example.com/audio.wav)'
      )

      verify_media_with_partial_path(
        '![Audio](/uploads/a123/audio.wav)',
        project_media_uri(@project, '/uploads/a123/audio.wav')
      )

      verify(
        'MathFilter: math as converted from GFM to HTML',
        '$`c = \pm\sqrt{a^2 + b^2}`$',
        # math block
        <<~GFM
          ```math
          c = \pm\sqrt{a^2 + b^2}
          ```
        GFM
      )

      aggregate_failures('MathFilter: math as transformed from HTML to KaTeX') do
        gfm = '$`c = \pm\sqrt{a^2 + b^2}`$'

        html = <<~HTML
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
        <<~GFM
          ```mermaid
          graph TD;
            A-->B;
          ```
        GFM
      )

      aggregate_failures('MermaidFilter: mermaid as transformed from HTML to SVG') do
        gfm = <<~GFM
          ```mermaid
          graph TD;
            A-->B;
          ```
        GFM

        html = <<~HTML
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
            A--&gt;B;</text>
          </svg>
        HTML

        output_gfm = html_to_gfm(html)
        expect(output_gfm.strip).to eq(gfm.strip)
      end

      verify(
        'SuggestionFilter: suggestion as converted from GFM to HTML',
        <<~GFM
          ```suggestion
          New
            And newer
          ```
        GFM
      )

      aggregate_failures('SuggestionFilter: suggestion as transformed from HTML to Vue component') do
        gfm = <<~GFM
          ```suggestion
          New
            And newer
          ```
        GFM

        html = <<~HTML
          <div class="md-suggestion">
            <div class="md-suggestion-header border-bottom-0 mt-2 js-suggestion-diff-header">
              <div class="js-suggestion-diff-header font-weight-bold">
                Suggested change
                <a href="/gitlab/help/user/discussions/index.md#suggest-changes" aria-label="Help" class="js-help-btn">
                  <svg aria-hidden="true" class="s16 ic-question-o link-highlight">
                    <use xlink:href="/gitlab/assets/icons.svg#question-o"></use>
                  </svg>
                </a>
              </div>
              <!---->
              <button type="button" class="btn qa-apply-btn js-apply-btn">Apply suggestion</button>
            </div>
            <table class="mb-3 md-suggestion-diff js-syntax-highlight code white">
              <tbody>
                <tr class="line_holder old">
                  <td class="diff-line-num old_line qa-old-diff-line-number old">9</td>
                  <td class="diff-line-num new_line old"></td>
                  <td class="line_content old"><span>Old
          </span></td>
                </tr>
                <tr class="line_holder new">
                  <td class="diff-line-num old_line new"></td>
                  <td class="diff-line-num new_line qa-new-diff-line-number new">9</td>
                  <td class="line_content new"><span>New
          </span></td>
                </tr>
                <tr class="line_holder new">
                  <td class="diff-line-num old_line new"></td>
                  <td class="diff-line-num new_line qa-new-diff-line-number new">10</td>
                  <td class="line_content new"><span>  And newer
          </span></td>
                </tr>
              </tbody>
            </table>
          </div>
        HTML

        output_gfm = html_to_gfm(html)
        expect(output_gfm.strip).to eq(gfm.strip)
      end

      verify(
        'SanitizationFilter',
        <<~GFM
        <sub>sub</sub>

        <dl>
          <dt>dt</dt>
          <dt>dt</dt>
          <dd>dd</dd>
          <dd>dd</dd>

          <dt>dt</dt>
          <dt>dt</dt>
          <dd>dd</dd>
          <dd>dd</dd>
        </dl>

        <kbd>kbd</kbd>

        <q>q</q>

        <samp>samp</samp>

        <var>var</var>

        <abbr title="HyperText &quot;Markup&quot; Language">HTML</abbr>

        <details>
        <summary>summary></summary>

        details
        </details>
        GFM
      )

      verify(
        'SanitizationFilter',
        <<~GFM,
          ```
          Plain text
          ```
        GFM
        <<~GFM,
          ```ruby
          def foo
            bar
          end
          ```
        GFM
        <<~GFM
          Foo

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
        <<~GFM,
          > Multiline Quote
          >
          > With multiple paragraphs
        GFM
        '![Image](https://example.com/image.png)',
        '# Heading with no anchor link',
        '[Link](https://example.com)',
        <<~GFM,
          * List item
          * List item 2
        GFM

        # multiline list item
        <<~GFM,
          * Multiline

            List item
        GFM

        # nested lists
        <<~GFM,
          * Nested
            * Lists
        GFM

        # list with blockquote
        <<~GFM,
          * List

            > Blockquote
        GFM
        <<~GFM,
          1. Ordered list item
          1. Ordered list item 2
        GFM

        # multiline ordered list item
        <<~GFM,
          1. Multiline

             Ordered list item
        GFM

        # nested ordered list
        <<~GFM,
          1. Nested
             1. Ordered lists
        GFM

        # list item followed by an HR
        <<~GFM,
          * list item

          ---
        GFM
        '# Heading',
        '## Heading',
        '### Heading',
        '#### Heading',
        '##### Heading',
        '###### Heading',
        '**Bold**',
        '*Italics*',
        '~~Strikethrough~~',
        '---',
        # table
        <<~GFM,
          | Centered | Right | Left |
          |:--------:|------:|------|
          | Foo | Bar | **Baz** |
          | Foo | Bar | **Baz** |
        GFM

        # table with empty heading
        <<~GFM
          |  | x | y |
          |--|---|---|
          | a | 1 | 0 |
          | b | 0 | 1 |
        GFM
      )
    end

    alias_method :gfm_to_html, :markdown

    def verify(label, *gfms)
      markdown_options = gfms.extract_options!

      aggregate_failures(label) do
        gfms.each do |gfm|
          html = gfm_to_html(gfm, markdown_options).gsub(/\A&#x000A;|&#x000A;\z/, '')
          output_gfm = html_to_gfm(html)
          expect(output_gfm.strip).to eq(gfm.strip)
        end
      end
    end

    def project_media_uri(project, media_path)
      "#{project_path(project)}#{media_path}"
    end

    def verify_media_with_partial_path(gfm, media_uri)
      html = gfm_to_html(gfm)
      output_gfm = html_to_gfm(html)
      expect(output_gfm).to include(media_uri)
    end

    # Fake a `current_user` helper
    def current_user
      @feat.user
    end
  end

  describe 'Copying code' do
    let(:project) { create(:project, :repository) }

    before do
      sign_in(project.owner)
    end

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
              <<~GFM,
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
          wait_for_requests
        end

        it_behaves_like 'copying code from a diff'
      end

      context 'parallel diff' do
        before do
          visit project_commit_path(project, sample_commit.id, view: 'parallel')
          wait_for_requests
        end

        it_behaves_like 'copying code from a diff'

        context 'selecting code on the left' do
          it 'copies as a code block' do
            verify(
              '[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_8_8"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_9_9"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_9"], [id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd_10_10"]',
              <<~GFM,
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
              <<~GFM,
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
            <<~GFM
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
            '.line[id="LC27"] .nl',
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
            <<~GFM
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
      wait_for_requests
      expect(output_gfm.strip).to eq(gfm.strip)
    end
  end

  def html_for_selector(selector)
    js = <<~JS
      (function(selector) {
        var els = document.querySelectorAll(selector);
        var htmls = [].slice.call(els).map(function(el) { return el.outerHTML; });
        return htmls.join("\\n");
      })("#{escape_javascript(selector)}")
    JS
    page.evaluate_script(js)
  end

  def html_to_gfm(html, transformer = 'transformGFMSelection', target: nil)
    js = <<~JS
      (function(html) {
        // Setting it off so the import already starts
        window.CopyAsGFM.nodeToGFM(document.createElement('div'));

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


        window.gfmCopytestRes = null;
        window.CopyAsGFM.nodeToGFM(node)
        .then((res) => {
          window.gfmCopytestRes = res;
        });
      })("#{escape_javascript(html)}")
    JS
    page.execute_script(js)

    loop until page.evaluate_script('window.gfmCopytestRes !== null')

    page.evaluate_script('window.gfmCopytestRes')
  end
end
