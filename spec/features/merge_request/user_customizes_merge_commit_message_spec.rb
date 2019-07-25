# frozen_string_literal: true

require 'rails_helper'

describe 'Merge request < User customizes merge commit message', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:issue_1) { create(:issue, project: project)}
  let(:issue_2) { create(:issue, project: project)}
  let(:merge_request) do
    create(
      :merge_request,
      :simple,
      source_project: project,
      description: "Description\n\nclosing #{issue_1.to_reference}, #{issue_2.to_reference}"
    )
  end
  let(:textbox) { page.find(:css, '#merge-message-edit', visible: false) }
  let(:default_message) do
    [
      "Merge branch 'feature' into 'master'",
      merge_request.title,
      "Closes #{issue_1.to_reference} and #{issue_2.to_reference}",
      "See merge request #{merge_request.to_reference(full: true)}"
    ].join("\n\n")
  end
  let(:message_with_description) do
    [
      "Merge branch 'feature' into 'master'",
      merge_request.title,
      merge_request.description,
      "See merge request #{merge_request.to_reference(full: true)}"
    ].join("\n\n")
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit project_merge_request_path(project, merge_request)
  end

  it 'toggles commit message between message with description and without description' do
    expect(page).not_to have_selector('#merge-message-edit')
    first('.js-mr-widget-commits-count').click
    expect(textbox).to be_visible
    expect(textbox.value).to eq(default_message)

    check('Include merge request description')

    expect(textbox.value).to eq(message_with_description)

    uncheck('Include merge request description')

    expect(textbox.value).to eq(default_message)
  end
end
