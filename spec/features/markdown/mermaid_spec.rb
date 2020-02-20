# frozen_string_literal: true

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

  it 'renders only 2 Mermaid blocks and ', :js do
    description = <<~MERMAID
    ```mermaid
    graph LR
    A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;
    ```
    ```mermaid
    graph LR
    A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;
    ```
    ```mermaid
    graph LR
    A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;B-->A;A-->B;
    ```
    MERMAID

    project = create(:project, :public)
    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    page.within('.description') do
      expect(page).to have_selector('svg')
      expect(page).to have_selector('pre.mermaid')
    end
  end

  it 'correctly sizes mermaid diagram inside <details> block', :js do
    description = <<~MERMAID
      <details>
      <summary>Click to show diagram</summary>

      ```mermaid
      graph TD;
        A-->B;
        A-->C;
        B-->D;
        C-->D;
      ```

      </details>
    MERMAID

    project = create(:project, :public)
    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    page.within('.description') do
      page.find('summary').click
      svg = page.find('svg.mermaid')

      expect(svg[:width].to_i).to be_within(5).of(120)
      expect(svg[:height].to_i).to be_within(5).of(220)
    end
  end
end
