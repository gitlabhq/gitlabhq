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
      expect(page).to have_selector('svg text', text: label)
    end
  end

  it 'renders linebreaks in Mermaid diagrams' do
    description = <<~MERMAID
      ```mermaid
      graph TD;
        A(Line 1<br>Line 2)-->B(Line 1<br/>Line 2);
        C(Line 1<br />Line 2)-->D(Line 1<br  />Line 2);
      ```
    MERMAID

    project = create(:project, :public)
    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    expected = '<text><tspan xml:space="preserve" dy="1em" x="1">Line 1</tspan><tspan xml:space="preserve" dy="1em" x="1">Line 2</tspan></text>'
    expect(page.html.scan(expected).count).to be(4)
  end
end
