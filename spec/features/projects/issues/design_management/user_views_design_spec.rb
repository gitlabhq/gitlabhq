# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views issue designs', :js, feature_category: :design_management do
  include DesignManagementTestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:guest_user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo, :public, maintainers: user, guests: guest_user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:design) { create(:design, :with_file, issue: issue) }
  let_it_be(:design_without_notes) { create(:design, :with_file, issue: issue) }
  let_it_be(:note) { create(:diff_note_on_design, noteable: design, author: user) }

  def add_diff_note_emoji(diff_note, emoji_name)
    page.within(first(".image-notes li#note_#{diff_note.id}.design-note")) do
      page.find('[data-testid="note-emoji-button"] .add-reaction-button').click

      page.within('.emoji-picker') do
        page.find('input[type="search"]').set(emoji_name)
        page.find('button[data-testid="emoji-button"]:first-child').click
      end
    end
  end

  def add_reply(text)
    page.within(find('.image-notes')) do
      find_by_testid('discussion-reply-tab').click
      find('.note-textarea').send_keys(text)

      find_by_testid('save-comment-button').click
      wait_for_requests
    end
  end

  def remove_diff_note_emoji(diff_note, emoji_name)
    page.within(first(".image-notes li#note_#{diff_note.id}.design-note")) do
      page.find(".awards button[data-emoji-name='#{emoji_name}']").click
    end
  end

  before do
    enable_design_management

    sign_in(user)

    visit project_issue_path(project, issue)
  end

  shared_examples 'design discussion emoji awards' do
    it 'allows user to add emoji reaction to a comment' do
      click_link design.filename

      add_diff_note_emoji(note, AwardEmoji::THUMBS_UP)

      expect(page.find("li#note_#{note.id} .awards"))
        .to have_selector(%(button[title="You reacted with :#{AwardEmoji::THUMBS_UP}:"]))
    end

    it 'allows user to remove emoji reaction from a comment' do
      click_link design.filename

      add_diff_note_emoji(note, AwardEmoji::THUMBS_UP)

      # Wait for emoji to be added
      wait_for_requests

      remove_diff_note_emoji(note, AwardEmoji::THUMBS_UP)

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

  it 'shows a design without notes' do
    empty_discussion_message = "Click on the image where you'd like to add a new comment."
    click_link design_without_notes.filename

    expect(page).not_to have_selector('.image-notes .design-note .note-text')
    expect(find_by_testid('new-discussion-disclaimer')).to have_content(empty_discussion_message)
  end

  it 'shows a comment within design' do
    click_link design.filename

    expect(page.find('.image-notes .design-note .note-text')).to have_content(note.note)
  end

  it 'highlights the current user in a comment' do
    click_link design.filename

    add_reply("@#{user.username} comment")

    page.within(find('.image-notes')) do
      expect(page).to have_selector '.gfm-project_member.current-user', text: user.username
    end
  end

  it 'allows toggling the replies on unresolved comment' do
    click_link design.filename

    add_reply('Reply to comment')

    page.within(find('.image-notes')) do
      expect(page).to have_content('Reply to comment')

      expect(find_by_testid('toggle-comments-wrapper')).to have_content('Collapse replies')

      find_by_testid('toggle-replies-button').click

      expect(page).to have_selector('.gl-avatars-inline .gl-avatar-link')
      expect(page).to have_content('1 reply')
    end
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
