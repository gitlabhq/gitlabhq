require 'rails_helper'

feature 'Issue markdown toolbar', :js do
  let(:project) { create(:project, :public) }
  let(:issue)   { create(:issue, project: project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)

    visit project_issue_path(project, issue)
  end

  it "doesn't include first new line when adding bold" do
    find('#note-body').native.send_keys('test')
    find('#note-body').native.send_key(:enter)
    find('#note-body').native.send_keys('bold')

    find('.js-main-target-form #note-body')
    page.evaluate_script('document.querySelectorAll(".js-main-target-form #note-body")[0].setSelectionRange(4, 9)')

    first('.toolbar-btn').click

    expect(find('#note-body')[:value]).to eq("test\n**bold**\n")
  end

  it "doesn't include first new line when adding underline" do
    find('#note-body').native.send_keys('test')
    find('#note-body').native.send_key(:enter)
    find('#note-body').native.send_keys('underline')

    find('.js-main-target-form #note-body')
    page.evaluate_script('document.querySelectorAll(".js-main-target-form #note-body")[0].setSelectionRange(4, 50)')

    find('.toolbar-btn:nth-child(2)').click

    expect(find('#note-body')[:value]).to eq("test\n*underline*\n")
  end
end
