# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User previews file while editing in single file editor', :js, feature_category: :source_code_management do
  include Features::SourceEditorSpecHelpers

  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be_with_reload(:user) { create(:user) }
  let(:content_mermaid_graph) do
    <<~MERMAID
    ```mermaid
    graph TD;
      A-->B;
      A-->C;
      B-->D;
      C-->D;
    ```
    MERMAID
  end

  let(:expected_mermaid_graph) do
    src = "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/-/sandbox/mermaid"
    %(<iframe src="#{src}" sandbox="allow-scripts allow-popups" frameborder="0" scrolling="no")
  end

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in user
    visit project_edit_blob_path(project, File.join(project.default_branch, 'README.md'))
  end

  context 'when user toggles preview' do
    it 'renders math equations correctly' do
      content = <<~MATH
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

      fill_editor(content)
      click_link 'Preview'
      wait_for_requests
      expect(page).to have_selector('.katex .mord.mathnormal', text: 'b')
      expect(page).to have_selector('.katex-display .mord.mathnormal', text: 'b')
      expect(page).to have_selector('.katex-display .mtable .col-align-l .mord.mathnormal', text: 'f')
    end

    it 'renders mermaid graphs correctly' do
      fill_editor(content_mermaid_graph)
      click_link 'Preview'
      wait_for_requests

      page.within('.js-markdown-code') do
        expect(page.html).to include(expected_mermaid_graph)
      end
    end
  end

  def fill_editor(content)
    wait_for_requests
    editor_set_value(content)
  end
end
