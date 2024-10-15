# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'kroki rendering', :js, feature_category: :markdown do
  let_it_be(:project) { create(:project, :public) }

  before do
    stub_application_setting(kroki_enabled: true, kroki_url: 'http://localhost:8000')
  end

  it 'shows kroki image' do
    plain_text = 'This text length is ignored. ' * 300

    description = <<~KROKI
      #{plain_text}
      ```plantuml
      A -> A: T
      ```
    KROKI

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    within('.description') do
      expect(page).to have_css('img')
      expect(page).not_to have_text 'Warning: Displaying this diagram might cause performance issues on this page.'
    end
  end

  it 'hides kroki image and shows warning alert when kroki source size is large' do
    plantuml_text = 'A -> A: T ' * 300

    description = <<~KROKI
      ```plantuml
      #{plantuml_text}
      ```
    KROKI

    issue = create(:issue, project: project, description: description)

    visit project_issue_path(project, issue)

    within('.description') do
      expect(page).not_to have_css('img')
      expect(page).to have_text 'Warning: Displaying this diagram might cause performance issues on this page.'

      click_button 'Display'

      expect(page).to have_css('img')
      expect(page).not_to have_text 'Warning: Displaying this diagram might cause performance issues on this page.'
    end
  end
end
