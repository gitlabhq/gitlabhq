require 'spec_helper'

describe 'Math rendering', :js do
  it 'renders inline and display math correctly' do
    description = <<~MATH
      This math is inline $`a^2+b^2=c^2`$.

      This is on a separate line
      ```math
      a^2+b^2=c^2
      ```
    MATH

    project = create(:project, :public)
    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    expect(page).to have_selector('.katex .mord.mathit', text: 'b')
    expect(page).to have_selector('.katex-display .mord.mathit', text: 'b')
  end
end
