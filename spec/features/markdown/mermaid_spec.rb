# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Mermaid rendering', :js do
  let_it_be(:project) { create(:project, :public) }

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

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests
    wait_for_mermaid

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

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests
    wait_for_mermaid

    # From https://github.com/mermaid-js/mermaid/blob/d3f8f03a7d03a052e1fe0251d5a6d8d1f48d67ee/src/dagre-wrapper/createLabel.js#L79-L82
    expected = %(<div xmlns="http://www.w3.org/1999/xhtml" style="display: inline-block; white-space: nowrap;">Line 1<br>Line 2</div>)
    expect(page.html.scan(expected).count).to be(4)
  end

  it 'does not allow XSS in HTML labels' do
    description = <<~MERMAID
      ```mermaid
      graph LR;
        A-->CLICK_HERE_AND_GET_BONUS;
        click A alert "aaa"
        click CLICK_HERE_AND_GET_BONUS "javascript:alert%28%64%6f%63%75%6d%65%6e%74%2e%64%6f%6d%61%69%6e%29" "Here is the XSS"
      ```
    MERMAID

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests
    wait_for_mermaid

    # From https://github.com/mermaid-js/mermaid/blob/d3f8f03a7d03a052e1fe0251d5a6d8d1f48d67ee/src/dagre-wrapper/createLabel.js#L79-L82
    expected = %(<div xmlns="http://www.w3.org/1999/xhtml" style="display: inline-block; white-space: nowrap;">CLICK_HERE_AND_GET_BONUS</div>)
    expect(page.html).to include(expected)
  end

  it 'renders only 2 Mermaid blocks and', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/234081' do
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

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests
    wait_for_mermaid

    page.within('.description') do
      expect(page).to have_selector('svg')
      expect(page).to have_selector('pre.mermaid')
    end
  end

  it 'correctly sizes mermaid diagram inside <details> block' do
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

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests
    wait_for_mermaid

    page.within('.description') do
      page.find('summary').click
      svg = page.find('svg.mermaid')

      expect(svg[:style]).to match(/max-width/)
      expect(svg[:width].to_i).to eq(100)
      expect(svg[:height].to_i).to be_within(5).of(236)
    end
  end

  it 'renders V2 state diagrams' do
    description = <<~MERMAID
    ```mermaid
    stateDiagram-v2
    [*] --> Idle
    Idle --> Active : CONTINUE
    state Active {
        [*] --> Run
        Run--> Stop: CONTINUE
        Stop--> Run: CONTINUE

        Run: Run
        Run: entry/start
        Run: check
    }
    ```
    MERMAID

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests
    wait_for_mermaid

    page.within('.description') do
      expect(page).to have_selector('svg')
    end
  end

  it 'correctly sizes mermaid diagram block' do
    description = <<~MERMAID
      ```mermaid
      graph TD;
        A-->B;
        A-->C;
        B-->D;
        C-->D;
      ```
    MERMAID

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests
    wait_for_mermaid

    expect(page).to have_css('svg.mermaid[style*="max-width"][width="100%"]')
  end

  it 'display button when diagram exceeds length', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/287806' do
    graph_edges = "A-->B;B-->A;" * 420

    description = <<~MERMAID
    ```mermaid
    graph LR
    #{graph_edges}
    ```
    MERMAID

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    page.within('.description') do
      expect(page).not_to have_selector('svg')

      expect(page).to have_selector('pre.mermaid')

      expect(page).to have_selector('.lazy-alert-shown')

      expect(page).to have_selector('.js-lazy-render-mermaid-container')
    end

    wait_for_requests
    wait_for_mermaid

    find('.js-lazy-render-mermaid').click

    page.within('.description') do
      expect(page).to have_selector('svg')

      expect(page).not_to have_selector('.js-lazy-render-mermaid-container')
    end
  end

  it 'does not render more than 50 mermaid blocks', :js, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/234081' } do
    graph_edges = "A-->B;B-->A;"

    description = <<~MERMAID
    ```mermaid
    graph LR
    #{graph_edges}
    ```
    MERMAID

    description *= 51

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    wait_for_requests
    wait_for_mermaid

    page.within('.description') do
      expect(page).to have_selector('svg')

      expect(page).to have_selector('.lazy-alert-shown')

      expect(page).to have_selector('.js-lazy-render-mermaid-container')
    end
  end

  it 'renders without any limits on wiki page', :js do
    graph_edges = "A-->B;B-->A;"

    description = <<~MERMAID
    ```mermaid
    graph LR
    #{graph_edges}
    ```
    MERMAID

    description *= 51

    project = create(:project, :public)

    wiki_page = build(:wiki_page, { container: project, content: description })
    wiki_page.create message: 'mermaid test commit' # rubocop:disable Rails/SaveBang
    wiki_page = project.wiki.find_page(wiki_page.slug)

    visit project_wiki_path(project, wiki_page)

    wait_for_requests
    wait_for_mermaid

    page.within('.js-wiki-page-content') do
      expect(page).not_to have_selector('.lazy-alert-shown')

      expect(page).not_to have_selector('.js-lazy-render-mermaid-container')
    end
  end
end

def wait_for_mermaid
  run_idle_callback = <<~RUN_IDLE_CALLBACK
  window.requestIdleCallback(() => {
    window.__CAPYBARA_IDLE_CALLBACK_EXEC__ = 1;
  })
  RUN_IDLE_CALLBACK

  page.evaluate_script(run_idle_callback)

  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until finished_rendering?
  end
end

def finished_rendering?
  check_idle_callback = <<~CHECK_IDLE_CALLBACK
    window.__CAPYBARA_IDLE_CALLBACK_EXEC__
  CHECK_IDLE_CALLBACK
  page.evaluate_script(check_idle_callback) == 1
end
