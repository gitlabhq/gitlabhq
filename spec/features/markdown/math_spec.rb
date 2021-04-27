# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Math rendering', :js do
  let!(:project) { create(:project, :public) }

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

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    expect(page).to have_selector('.katex .mord.mathnormal', text: 'b')
    expect(page).to have_selector('.katex-display .mord.mathnormal', text: 'b')
    expect(page).to have_selector('.katex-display .mtable .col-align-l .mord.mathnormal', text: 'f')
  end

  it 'only renders non XSS links' do
    description = <<~MATH
      This link is valid $`\\href{javascript:alert('xss');}{xss}`$.

      This link is valid $`\\href{https://gitlab.com}{Gitlab}`$.
    MATH

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    page.within '.description > .md' do
      # unfortunately there is no class selector for KaTeX's "unsupported command"
      # formatting so we must match the style attribute
      expect(page).to have_selector('.katex-html .mord[style*="color:"][style*="#cc0000"]', text: '\href')
      expect(page).to have_selector('.katex-html a', text: 'Gitlab')
    end
  end

  it 'renders lazy load button' do
    description = <<~MATH
      ```math
        \Huge \sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{\sqrt{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
      ```
    MATH

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    page.within '.description > .md' do
      expect(page).to have_selector('.js-lazy-render-math')
    end
  end
end
