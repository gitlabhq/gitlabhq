# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sandboxed Mermaid rendering', :js do
  let_it_be(:project) { create(:project, :public) }

  before do
    stub_feature_flags(sandboxed_mermaid: true)
  end

  it 'includes mermaid frame correctly' do
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

    expected = %(<iframe src="/-/sandbox/mermaid" sandbox="allow-scripts allow-popups" frameborder="0" scrolling="no")
    expect(page.html).to include(expected)
  end
end
