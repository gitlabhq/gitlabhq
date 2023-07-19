# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views issue designs', :js, feature_category: :design_management do
  include DesignManagementTestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:guest_user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:design) { create(:design, :with_file, issue: issue) }
  let_it_be(:note) { create(:diff_note_on_design, noteable: design, author: user) }

  def add_diff_note_emoji(diff_note, emoji_name)
    page.within(first(".image-notes li#note_#{diff_note.id}.design-note")) do
      page.find('[data-testid="note-emoji-button"] .note-emoji-button').click

      page.within('ul.dropdown-menu') do
        page.find('input[type="search"]').set(emoji_name)
        page.find('button[data-testid="emoji-button"]:first-child').click
      end
    end
  end

  def remove_diff_note_emoji(diff_note, emoji_name)
    page.within(first(".image-notes li#note_#{diff_note.id}.design-note")) do
      page.find(".awards button[data-emoji-name='#{emoji_name}']").click
    end
  end

  before_all do
    project.add_maintainer(user)
    project.add_guest(guest_user)
  end

  before do
    enable_design_management

    sign_in(user)

    visit project_issue_path(project, issue)
  end

  shared_examples 'design discussion emoji awards' do
    it 'allows user to add emoji reaction to a comment' do
      click_link design.filename

      add_diff_note_emoji(note, 'thumbsup')

      expect(page.find("li#note_#{note.id} .awards")).to have_selector('button[title="You reacted with :thumbsup:"]')
    end

    it 'allows user to remove emoji reaction from a comment' do
      click_link design.filename

      add_diff_note_emoji(note, 'thumbsup')

      # Wait for emoji to be added
      wait_for_requests

      remove_diff_note_emoji(note, 'thumbsup')

      # Only award emoji that was present has been removed
      expect(page.find("li#note_#{note.id}")).not_to have_selector('.awards')
    end
  end

  it 'opens design detail' do
    click_link design.filename

    page.within(find('.js-design-header')) do
      expect(page).to have_content(design.filename)
    end

    expect(page).to have_selector('.js-design-image')
  end

  it 'shows a comment within design' do
    click_link design.filename

    expect(page.find('.image-notes .design-note .note-text')).to have_content(note.note)
  end

  it_behaves_like 'design discussion emoji awards'

  context 'when user is guest' do
    before do
      enable_design_management

      sign_in(guest_user)

      visit project_issue_path(project, issue)
    end

    it_behaves_like 'design discussion emoji awards'
  end

  context 'when svg file is loaded in design detail' do
    let_it_be(:file) { Rails.root.join('spec/fixtures/svg_without_attr.svg') }
    let_it_be(:design) { create(:design, :with_file, filename: 'svg_without_attr.svg', file: file, issue: issue) }

    before do
      visit designs_project_issue_path(
        project,
        issue,
        { vueroute: design.filename }
      )
      wait_for_requests
    end

    it 'check if svg is loading' do
      expect(page).to have_selector(
        ".js-design-image > img[alt='svg_without_attr.svg']",
        count: 1,
        visible: :hidden
      )
    end
  end
end
