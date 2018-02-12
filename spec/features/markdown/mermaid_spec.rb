require 'spec_helper'

describe 'Mermaid rendering', :js do
  it 'renders Mermaid diagrams correctly' do
    description = <<~MERMAID
      ```mermaid
      graph TD;
        A-->B;
        A-->C;
        B-->D;
        C-->D;
      ```
    MERMAID

    project = create(:project, :public)
    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    %w[A B C D].each do |label|
      expect(page).to have_selector('svg foreignObject', text: label)
    end
  end
end
