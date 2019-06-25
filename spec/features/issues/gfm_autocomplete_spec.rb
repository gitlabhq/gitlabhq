require 'rails_helper'

describe 'GFM autocomplete', :js do
  let(:issue_xss_title) { 'This will execute alert<img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;' }
  let(:user_xss_title) { 'eve <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;' }
  let(:label_xss_title) { 'alert label &lt;img src=x onerror="alert(\'Hello xss\');" a' }
  let(:milestone_xss_title) { 'alert milestone &lt;img src=x onerror="alert(\'Hello xss\');" a' }

  let(:user_xss) { create(:user, name: user_xss_title, username: 'xss.user') }
  let(:user) { create(:user, name: '💃speciąl someone💃', username: 'someone.special') }
  let(:project) { create(:project) }
  let(:label) { create(:label, project: project, title: 'special+') }
  let(:issue) { create(:issue, project: project) }

  before do
    project.add_maintainer(user)
    project.add_maintainer(user_xss)

    sign_in(user)
    visit project_issue_path(project, issue)

    wait_for_requests
  end

  it 'updates issue description with GFM reference' do
    find('.js-issuable-edit').click

    simulate_input('#issue-description', "@#{user.name[0...3]}")

    wait_for_requests

    find('.atwho-view .cur').click

    click_button 'Save changes'

    wait_for_requests

    expect(find('.description')).to have_content(user.to_reference)
  end

  it 'opens autocomplete menu when field starts with text' do
    page.within '.timeline-content-form' do
      find('#note-body').native.send_keys('@')
    end

    expect(page).to have_selector('.atwho-container')
  end

  it 'opens autocomplete menu for Issues when field starts with text with item escaping HTML characters' do
    create(:issue, project: project, title: issue_xss_title)

    page.within '.timeline-content-form' do
      find('#note-body').native.send_keys('#')
    end

    wait_for_requests

    expect(page).to have_selector('.atwho-container')

    page.within '.atwho-container #at-view-issues' do
      expect(page.all('li').first.text).to include(issue_xss_title)
    end
  end

  it 'opens autocomplete menu for Username when field starts with text with item escaping HTML characters' do
    page.within '.timeline-content-form' do
      find('#note-body').native.send_keys('@ev')
    end

    wait_for_requests

    expect(page).to have_selector('.atwho-container')

    page.within '.atwho-container #at-view-users' do
      expect(find('li').text).to have_content(user_xss.username)
    end
  end

  it 'opens autocomplete menu for Milestone when field starts with text with item escaping HTML characters' do
    create(:milestone, project: project, title: milestone_xss_title)

    page.within '.timeline-content-form' do
      find('#note-body').native.send_keys('%')
    end

    wait_for_requests

    expect(page).to have_selector('.atwho-container')

    page.within '.atwho-container #at-view-milestones' do
      expect(find('li').text).to have_content('alert milestone')
    end
  end

  it 'doesnt open autocomplete menu character is prefixed with text' do
    page.within '.timeline-content-form' do
      find('#note-body').native.send_keys('testing')
      find('#note-body').native.send_keys('@')
    end

    expect(page).not_to have_selector('.atwho-view')
  end

  it 'doesnt select the first item for non-assignee dropdowns' do
    page.within '.timeline-content-form' do
      find('#note-body').native.send_keys(':')
    end

    expect(page).to have_selector('.atwho-container')

    wait_for_requests

    expect(find('#at-view-58')).not_to have_selector('.cur:first-of-type')
  end

  it 'does not open autocomplete menu when ":" is prefixed by a number and letters' do
    note = find('#note-body')

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
      find('#note-body').native.send_keys('@')
    end

    expect(page).to have_selector('.atwho-container')

    wait_for_requests

    expect(find('#at-view-users')).to have_selector('.cur:first-of-type')
  end

  it 'includes items for assignee dropdowns with non-ASCII characters in name' do
    page.within '.timeline-content-form' do
      find('#note-body').native.send_keys('')
      simulate_input('#note-body', "@#{user.name[0...8]}")
    end

    expect(page).to have_selector('.atwho-container')

    wait_for_requests

    expect(find('#at-view-users')).to have_content(user.name)
  end

  it 'selects the first item for non-assignee dropdowns if a query is entered' do
    page.within '.timeline-content-form' do
      find('#note-body').native.send_keys(':1')
    end

    expect(page).to have_selector('.atwho-container')

    wait_for_requests

    expect(find('#at-view-58')).to have_selector('.cur:first-of-type')
  end

  context 'if a selected value has special characters' do
    it 'wraps the result in double quotes' do
      note = find('#note-body')
      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys('')
        simulate_input('#note-body', "~#{label.title[0]}")
      end

      label_item = find('.atwho-view li', text: label.title)

      expect_to_wrap(true, label_item, note, label.title)
    end

    it "shows dropdown after a new line" do
      note = find('#note-body')
      page.within '.timeline-content-form' do
        note.native.send_keys('test')
        note.native.send_keys(:enter)
        note.native.send_keys(:enter)
        note.native.send_keys('@')
      end

      expect(page).to have_selector('.atwho-container')
    end

    it "does not show dropdown when preceded with a special character" do
      note = find('#note-body')
      page.within '.timeline-content-form' do
        note.native.send_keys("@")
      end

      expect(page).to have_selector('.atwho-container')

      page.within '.timeline-content-form' do
        note.native.send_keys("@")
      end

      expect(page).to have_selector('.atwho-container', visible: false)
    end

    it "does not throw an error if no labels exist" do
      note = find('#note-body')
      page.within '.timeline-content-form' do
        note.native.send_keys('~')
      end

      expect(page).to have_selector('.atwho-container', visible: false)
    end

    it 'doesn\'t wrap for assignee values' do
      note = find('#note-body')
      page.within '.timeline-content-form' do
        note.native.send_keys("@#{user.username[0]}")
      end

      user_item = find('.atwho-view li', text: user.username)

      expect_to_wrap(false, user_item, note, user.username)
    end

    it 'doesn\'t wrap for emoji values' do
      note = find('#note-body')
      page.within '.timeline-content-form' do
        note.native.send_keys(":cartwheel_")
      end

      emoji_item = find('.atwho-view li', text: 'cartwheel_tone1')

      expect_to_wrap(false, emoji_item, note, 'cartwheel_tone1')
    end

    it 'doesn\'t open autocomplete after non-word character' do
      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys("@#{user.username[0..2]}!")
      end

      expect(page).not_to have_selector('.atwho-view')
    end

    it 'doesn\'t open autocomplete if there is no space before' do
      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys("hello:#{user.username[0..2]}")
      end

      expect(page).not_to have_selector('.atwho-view')
    end

    it 'triggers autocomplete after selecting a quick action' do
      note = find('#note-body')
      page.within '.timeline-content-form' do
        note.native.send_keys('/as')
      end

      find('.atwho-view li', text: '/assign')
      note.native.send_keys(:tab)

      user_item = find('.atwho-view li', text: user.username)
      expect(user_item).to have_content(user.username)
    end
  end

  context 'labels' do
    it 'opens autocomplete menu for Labels when field starts with text with item escaping HTML characters' do
      create(:label, project: project, title: label_xss_title)

      note = find('#note-body')

      # It should show all the labels on "~".
      type(note, '~')

      wait_for_requests

      page.within '.atwho-container #at-view-labels' do
        expect(find('.atwho-view-ul').text).to have_content('alert label')
      end
    end

    it 'allows colons when autocompleting scoped labels' do
      create(:label, project: project, title: 'scoped:label')

      note = find('#note-body')
      type(note, '~scoped:')

      wait_for_requests

      page.within '.atwho-container #at-view-labels' do
        expect(find('.atwho-view-ul').text).to have_content('scoped:label')
      end
    end

    it 'allows colons when autocompleting scoped labels with double colons' do
      create(:label, project: project, title: 'scoped::label')

      note = find('#note-body')
      type(note, '~scoped::')

      wait_for_requests

      page.within '.atwho-container #at-view-labels' do
        expect(find('.atwho-view-ul').text).to have_content('scoped::label')
      end
    end

    it 'allows spaces when autocompleting multi-word labels' do
      create(:label, project: project, title: 'Accepting merge requests')

      note = find('#note-body')
      type(note, '~Accepting merge')

      wait_for_requests

      page.within '.atwho-container #at-view-labels' do
        expect(find('.atwho-view-ul').text).to have_content('Accepting merge requests')
      end
    end

    it 'only autocompletes the latest label' do
      create(:label, project: project, title: 'Accepting merge requests')
      create(:label, project: project, title: 'Accepting job applicants')

      note = find('#note-body')
      type(note, '~Accepting merge requests foo bar ~Accepting job')

      wait_for_requests

      page.within '.atwho-container #at-view-labels' do
        expect(find('.atwho-view-ul').text).to have_content('Accepting job applicants')
      end
    end

    it 'does not autocomplete labels if no tilde is typed' do
      create(:label, project: project, title: 'Accepting merge requests')

      note = find('#note-body')
      type(note, 'Accepting merge')

      wait_for_requests

      expect(page).not_to have_css('.atwho-container #at-view-labels')
    end
  end

  shared_examples 'autocomplete suggestions' do
    it 'suggests objects correctly' do
      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys(object.class.reference_prefix)
      end

      page.within '.atwho-container' do
        expect(page).to have_content(object.title)

        find('ul li').click
      end

      expect(find('.new-note #note-body').value).to include(expected_body)
    end
  end

  context 'issues' do
    let(:object) { issue }
    let(:expected_body) { object.to_reference }

    it_behaves_like 'autocomplete suggestions'
  end

  context 'merge requests' do
    let(:object) { create(:merge_request, source_project: project) }
    let(:expected_body) { object.to_reference }

    it_behaves_like 'autocomplete suggestions'
  end

  context 'project snippets' do
    let!(:object) { create(:project_snippet, project: project, title: 'code snippet') }
    let(:expected_body) { object.to_reference }

    it_behaves_like 'autocomplete suggestions'
  end

  context 'label' do
    let!(:object) { label }
    let(:expected_body) { object.title }

    it_behaves_like 'autocomplete suggestions'
  end

  context 'milestone' do
    let!(:object) { create(:milestone, project: project) }
    let(:expected_body) { object.to_reference }

    it_behaves_like 'autocomplete suggestions'
  end

  private

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

  def expect_labels(shown: nil, not_shown: nil)
    page.within('.atwho-container') do
      if shown
        expect(page).to have_selector('.atwho-view li', count: shown.size)
        shown.each { |label| expect(page).to have_content(label.title) }
      end

      if not_shown
        expect(page).not_to have_selector('.atwho-view li') unless shown
        not_shown.each { |label| expect(page).not_to have_content(label.title) }
      end
    end
  end

  # `note` is a textarea where the given text should be typed.
  # We don't want to find it each time this function gets called.
  def type(note, text)
    page.within('.timeline-content-form') do
      note.set('')
      note.native.send_keys(text)
    end
  end
end
