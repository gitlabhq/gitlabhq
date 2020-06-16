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
    MATH

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    expect(page).to have_selector('.katex .mord.mathdefault', text: 'b')
    expect(page).to have_selector('.katex-display .mord.mathdefault', text: 'b')
  end

  it 'only renders non XSS links' do
    description = <<~MATH
      This link is valid $`\\href{javascript:alert('xss');}{xss}`$.

      This link is valid $`\\href{https://gitlab.com}{Gitlab}`$.
    MATH

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    page.within '.description > .md' do
      expect(page).to have_selector('.katex-error')
      expect(page).to have_selector('.katex-html a', text: 'Gitlab')
    end
  end
end
