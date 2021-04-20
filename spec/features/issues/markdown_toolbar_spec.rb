# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue markdown toolbar', :js do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue)   { create(:issue, project: project) }
  let_it_be(:user)    { create(:user) }

  before do
    sign_in(user)

    visit project_issue_path(project, issue)
  end

  it "doesn't include first new line when adding bold" do
    fill_in 'Comment', with: "test\nbold"

    page.evaluate_script('document.getElementById("note-body").setSelectionRange(4, 9)')

    click_button 'Add bold text'

    expect(find_field('Comment').value).to eq("test\n**bold**\n")
  end

  it "doesn't include first new line when adding underline" do
    fill_in 'Comment', with: "test\nunderline"

    page.evaluate_script('document.getElementById("note-body").setSelectionRange(4, 50)')

    click_button 'Add italic text'

    expect(find_field('Comment').value).to eq("test\n_underline_\n")
  end
end
