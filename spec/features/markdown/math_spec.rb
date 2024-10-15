# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Math rendering', :js, feature_category: :markdown do
  let_it_be(:project) { create(:project, :public) }

  it 'renders inline and display math correctly' do
    description = <<~MATH
      This math is inline $`a^2+b^2=c^2`$.

      This is on a separate line
      ```math
      a^2+b^2=c^2
      ```

      This math is aligned

      ```math
      \\begin{align*}
        a&=b+c \\\\
        d+e&=f
      \\end{align*}
      ```
    MATH

    create_and_visit_issue_with_description(description)

    expect(page).to have_selector('.katex .mord.mathnormal', text: 'b')
    expect(page).to have_selector('.katex-display .mord.mathnormal', text: 'b')
    expect(page).to have_selector('.katex-display .mtable .col-align-l .mord.mathnormal', text: 'f')
  end

  it 'only renders non XSS links' do
    description = <<~MATH
      This link is valid $`\\href{javascript:alert('xss');}{xss}`$.

      This link is valid $`\\href{https://gitlab.com}{Gitlab}`$.
    MATH

    create_and_visit_issue_with_description(description)

    page.within '.description > .md' do
      # unfortunately there is no class selector for KaTeX's "unsupported command"
      # formatting so we must match the style attribute
      expect(page).to have_selector('.katex-html .mord[style*="color:"][style*="#cc0000"]', text: '\href')
      expect(page).to have_selector('.katex-html a', text: 'Gitlab')
    end
  end

  describe 'applying limits on math rendering' do
    let(:lazy_load_description) do
      <<~MATH
        ```math
          \Huge \sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
        ```
      MATH
    end

    let(:excessive_expansion_description) do
      <<~MATH
        ```math
        #{'\\mod e ' * 150}
        ```
      MATH
    end

    context 'when limits should be applied (default)' do
      it 'renders lazy load button' do
        create_and_visit_issue_with_description(lazy_load_description)

        page.within '.description > .md' do
          expect(page).to have_selector('[role="alert"]', text: /math block exceeds 1000 characters/)
        end
      end

      it 'allows many expansions', :js do
        description = <<~MATH
          ```math
          #{'\\mod e ' * 100}
          ```
        MATH

        create_and_visit_issue_with_description(description)

        page.within '.description > .md' do
          expect(page).not_to have_selector('.katex-error')
        end
      end

      it 'shows error message when too many expansions', :js do
        create_and_visit_issue_with_description(excessive_expansion_description)

        page.within '.description > .md' do
          click_button 'Display anyway'

          expect(page).to have_selector('.katex-error', text: /Too many expansions/)
        end
      end

      it 'renders with limits on wiki page', :js do
        wiki_page = build(:wiki_page, { container: project, content: lazy_load_description })
        wiki_page.create message: 'math test commit' # rubocop:disable Rails/SaveBang
        wiki_page = project.wiki.find_page(wiki_page.slug)

        visit project_wiki_path(project, wiki_page)

        wait_for_requests

        page.within '.js-wiki-page-content' do
          # the find is needed to ensure the lazy container is loaded, otherwise
          # it can be a flaky test, similar to
          # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25408
          find('[role="alert"]')

          expect(page).to have_selector('[role="alert"]', text: /math block exceeds 1000 characters/)
        end
      end
    end

    context 'when limits are disabled' do
      let_it_be(:namespace_settings) { create(:namespace_settings, math_rendering_limits_enabled: false) }
      let_it_be(:group) { create(:group, namespace_settings: namespace_settings) }
      let_it_be(:project) { create(:project, :public, group: group) }

      it 'does not render lazy load button' do
        create_and_visit_issue_with_description(lazy_load_description)

        page.within '.description > .md' do
          expect(page).not_to have_selector('button', text: 'Display anyway')
          expect(page).not_to have_selector('[role="alert"]', text: /math block exceeds 1000 characters/)
        end
      end

      it 'does not show error message when too many expansions', :js do
        create_and_visit_issue_with_description(excessive_expansion_description)

        page.within '.description > .md' do
          expect(page).not_to have_selector('button', text: 'Display anyway')
          expect(page).not_to have_selector('.katex-error', text: /Too many expansions/)
        end
      end
    end
  end

  it 'shows error message when other errors are generated', :js do
    description = <<~MATH
      ```math
      \\unknown
      ```
    MATH

    create_and_visit_issue_with_description(description)

    page.within '.description > .md' do
      expect(page).to have_selector('.katex-error',
        text: /There was an error rendering this math block. KaTeX parse error/)
    end
  end

  it 'escapes HTML in error', :js do
    description = <<~MATH
      ```math
      \\unknown <script>
      ```
    MATH

    create_and_visit_issue_with_description(description)

    page.within '.description > .md' do
      expect(page).to have_selector('.katex-error', text: /&amp;lt;script&amp;gt;/)
    end
  end

  it 'uses math-content-display for display math', :js do
    description = <<~MATH
      ```math
        1 + 2
      ```
    MATH

    create_and_visit_issue_with_description(description)

    page.within '.description > .md' do
      expect(page).to have_selector('.math-content-display')
    end
  end

  it 'uses math-content-inline for inline math', :js do
    description = 'one $`1 + 2`$ two'

    create_and_visit_issue_with_description(description)

    page.within '.description > .md' do
      expect(page).to have_selector('.math-content-inline')
    end
  end

  context 'when math tries to cover other elements on the page' do
    it 'prevents hijacking for display math', :js do
      description = <<~MATH
        [test link](#)

        ```math
          \\hskip{-200pt}\\href{https://example.com}{\\smash{\\raisebox{20em}{$\\smash{\\raisebox{20em}{$\\phantom{\\underset{\\underset{\\underset{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}}{\\underset{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}}}{\\underset{\\underset{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}}{}}}$}}$}}}
        ```
      MATH

      issue = create_and_visit_issue_with_description(description)

      page.within '.description > .md' do
        click_link 'test link'

        expect(page).to have_current_path(project_issue_path(project, issue))
      end
    end

    it 'prevents hijacking for inline math', :js do
      description = <<~MATH
        [test link](#) $`\\hskip{-200pt}\\href{https://example.com}{\\smash{\\raisebox{20em}{$\\smash{\\raisebox{20em}{$\\phantom{\\underset{\\underset{\\underset{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}}{\\underset{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}}}{\\underset{\\underset{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}{\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}\\rule{20em}{20em}}}{}}}$}}$}}}`$
      MATH

      issue = create_and_visit_issue_with_description(description)

      page.within '.description > .md' do
        click_link 'test link'

        expect(page).to have_current_path(project_issue_path(project, issue))
      end
    end
  end

  def create_and_visit_issue_with_description(description)
    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests

    issue
  end
end
