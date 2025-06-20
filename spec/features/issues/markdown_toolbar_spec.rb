# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue markdown toolbar', :js, feature_category: :text_editors do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue)   { create(:issue, project: project) }
  let_it_be(:user)    { create(:user) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    sign_in(user)

    visit project_issue_path(project, issue)
  end

  it "doesn't include first new line when adding bold" do
    fill_in 'Add a reply', with: "test\nbold"

    page.evaluate_script('document.getElementById("work-item-add-or-edit-comment").setSelectionRange(4, 9)')

    click_button 'Add bold text'

    expect(find_field('Add a reply').value).to eq("test\n**bold**\n")
  end

  it "doesn't include first new line when adding underline" do
    fill_in 'Add a reply', with: "test\nunderline"

    page.evaluate_script('document.getElementById("work-item-add-or-edit-comment").setSelectionRange(4, 50)')

    click_button 'Add italic text'

    expect(find_field('Add a reply').value).to eq("test\n_underline_\n")
  end

  it "makes sure bold works fine after preview" do
    fill_in 'Add a reply', with: "test"

    click_button 'Preview'
    click_button 'Continue editing'

    page.evaluate_script('document.getElementById("work-item-add-or-edit-comment").setSelectionRange(0, 4)')

    click_button 'Add bold text'

    expect(find_field('Add a reply').value).to eq("**test**")
  end
end
