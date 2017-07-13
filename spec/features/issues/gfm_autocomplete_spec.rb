require 'rails_helper'

feature 'GFM autocomplete', feature: true, js: true do
  let(:user)    { create(:user, name: '💃speciąl someone💃', username: 'someone.special') }
  let(:project) { create(:project) }
  let(:label) { create(:label, project: project, title: 'special+') }
  let(:issue)   { create(:issue, project: project) }

  before do
    project.team << [user, :master]
    sign_in(user)
    visit project_issue_path(project, issue)

    wait_for_requests
  end

  it 'updates issue descripton with GFM reference' do
    find('.issuable-edit').click

    find('#issue-description').native.send_keys("@#{user.name[0...3]}")

    find('.atwho-view .cur').trigger('click')

    click_button 'Save changes'

    expect(find('.description')).to have_content(user.to_reference)
  end

  it 'opens autocomplete menu when field starts with text' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('')
      find('#note_note').native.send_keys('@')
    end

    expect(page).to have_selector('.atwho-container')
  end

  it 'doesnt open autocomplete menu character is prefixed with text' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('testing')
      find('#note_note').native.send_keys('@')
    end

    expect(page).not_to have_selector('.atwho-view')
  end

  it 'doesnt select the first item for non-assignee dropdowns' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('')
      find('#note_note').native.send_keys(':')
    end

    expect(page).to have_selector('.atwho-container')

    wait_for_requests

    expect(find('#at-view-58')).not_to have_selector('.cur:first-of-type')
  end

  it 'does not open autocomplete menu when ":" is prefixed by a number and letters' do
    note = find('#note_note')

    # Number.
    page.within '.timeline-content-form' do
      note.native.send_keys('7:')
    end

    expect(page).not_to have_selector('.atwho-view')

    # ASCII letter.
    page.within '.timeline-content-form' do
      note.set('')
      note.native.send_keys('w:')
    end

    expect(page).not_to have_selector('.atwho-view')

    # Non-ASCII letter.
    page.within '.timeline-content-form' do
      note.set('')
      note.native.send_keys('Ё:')
    end

    expect(page).not_to have_selector('.atwho-view')
  end

  it 'selects the first item for assignee dropdowns' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('')
      find('#note_note').native.send_keys('@')
    end

    expect(page).to have_selector('.atwho-container')

    wait_for_requests

    expect(find('#at-view-64')).to have_selector('.cur:first-of-type')
  end

  it 'includes items for assignee dropdowns with non-ASCII characters in name' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('')
      find('#note_note').native.send_keys("@#{user.name[0...8]}")
    end

    expect(page).to have_selector('.atwho-container')

    wait_for_requests

    expect(find('#at-view-64')).to have_content(user.name)
  end

  it 'selects the first item for non-assignee dropdowns if a query is entered' do
    page.within '.timeline-content-form' do
      find('#note_note').native.send_keys('')
      find('#note_note').native.send_keys(':1')
    end

    expect(page).to have_selector('.atwho-container')

    wait_for_requests

    expect(find('#at-view-58')).to have_selector('.cur:first-of-type')
  end

  context 'if a selected value has special characters' do
    it 'wraps the result in double quotes' do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('')
        note.native.send_keys("~#{label.title[0]}")
        note.click
      end

      label_item = find('.atwho-view li', text: label.title)

      expect_to_wrap(true, label_item, note, label.title)
    end

    it "shows dropdown after a new line" do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('test')
        note.native.send_keys(:enter)
        note.native.send_keys(:enter)
        note.native.send_keys('@')
      end

      expect(page).to have_selector('.atwho-container')
    end

    it "does not show dropdown when preceded with a special character" do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('')
        note.native.send_keys("@")
        note.click
      end

      expect(page).to have_selector('.atwho-container')

      page.within '.timeline-content-form' do
        note.native.send_keys("@")
        note.click
      end

      expect(page).to have_selector('.atwho-container', visible: false)
    end

    it "does not throw an error if no labels exist" do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('')
        note.native.send_keys('~')
        note.click
      end

      expect(page).to have_selector('.atwho-container', visible: false)
    end

    it 'doesn\'t wrap for assignee values' do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('')
        note.native.send_keys("@#{user.username[0]}")
        note.click
      end

      user_item = find('.atwho-view li', text: user.username)

      expect_to_wrap(false, user_item, note, user.username)
    end

    it 'doesn\'t wrap for emoji values' do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('')
        note.native.send_keys(":cartwheel")
        note.click
      end

      emoji_item = find('.atwho-view li', text: 'cartwheel_tone1')

      expect_to_wrap(false, emoji_item, note, 'cartwheel_tone1')
    end

    it 'doesn\'t open autocomplete after non-word character' do
      page.within '.timeline-content-form' do
        find('#note_note').native.send_keys("@#{user.username[0..2]}!")
      end

      expect(page).not_to have_selector('.atwho-view')
    end

    it 'doesn\'t open autocomplete if there is no space before' do
      page.within '.timeline-content-form' do
        find('#note_note').native.send_keys("hello:#{user.username[0..2]}")
      end

      expect(page).not_to have_selector('.atwho-view')
    end

    it 'triggers autocomplete after selecting a quick action' do
      note = find('#note_note')
      page.within '.timeline-content-form' do
        note.native.send_keys('')
        note.native.send_keys('/as')
        note.click
      end

      find('.atwho-view li', text: '/assign').native.send_keys(:tab)

      user_item = find('.atwho-view li', text: user.username)
      expect(user_item).to have_content(user.username)
    end

    def expect_to_wrap(should_wrap, item, note, value)
      expect(item).to have_content(value)
      expect(item).not_to have_content("\"#{value}\"")

      item.click

      if should_wrap
        expect(note.value).to include("\"#{value}\"")
      else
        expect(note.value).not_to include("\"#{value}\"")
      end
    end
  end
end
