require 'spec_helper'

feature 'Clicking toggle commit message link', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
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
  let(:textbox) { page.find(:css, '.js-commit-message', visible: false) }
  let(:include_link) { page.find(:css, '.js-with-description-link', visible: false) }
  let(:do_not_include_link) { page.find(:css, '.js-without-description-link', visible: false) }
  let(:default_message) do
    [
      "Merge branch 'feature' into 'master'",
      merge_request.title,
      "Closes #{issue_1.to_reference} and #{issue_2.to_reference}",
      "See merge request #{merge_request.to_reference}"
    ].join("\n\n")
  end
  let(:message_with_description) do
    [
      "Merge branch 'feature' into 'master'",
      merge_request.title,
      merge_request.description,
      "See merge request #{merge_request.to_reference}"
    ].join("\n\n")
  end

  before do
    project.team << [user, :master]

    login_as user

    visit namespace_project_merge_request_path(project.namespace, project, merge_request)

    expect(textbox).not_to be_visible
    click_link "Modify commit message"
    expect(textbox).to be_visible
  end

  it "toggles commit message between message with description and without description " do
    expect(textbox.value).to eq(default_message)

    click_link "Include description in commit message"

    expect(textbox.value).to eq(message_with_description)

    click_link "Don't include description in commit message"

    expect(textbox.value).to eq(default_message)
  end

  it "toggles link between 'Include description' and 'Don't include description'" do
    expect(include_link).to be_visible
    expect(do_not_include_link).not_to be_visible

    click_link "Include description in commit message"

    expect(include_link).not_to be_visible
    expect(do_not_include_link).to be_visible

    click_link "Don't include description in commit message"

    expect(include_link).to be_visible
    expect(do_not_include_link).not_to be_visible
  end
end
