# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GFM autocomplete', :js do
  let_it_be(:user_xss_title) { 'eve <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;' }
  let_it_be(:user_xss) { create(:user, name: user_xss_title, username: 'xss.user') }
  let_it_be(:user) { create(:user, name: '💃speciąl someone💃', username: 'someone.special') }
  let_it_be(:group) { create(:group, name: 'Ancestor') }
  let_it_be(:child_group) { create(:group, parent: group, name: 'My group') }
  let_it_be(:project) { create(:project, group: child_group) }
  let_it_be(:label) { create(:label, project: project, title: 'special+') }

  let(:issue) { create(:issue, project: project) }

  before_all do
    project.add_maintainer(user)
    project.add_maintainer(user_xss)
  end

  describe 'when tribute_autocomplete feature flag is off' do
    before do
      stub_feature_flags(tribute_autocomplete: false)

      sign_in(user)
      visit project_issue_path(project, issue)

      wait_for_requests
    end

    it 'updates issue description with GFM reference' do
      find('.js-issuable-edit').click

      wait_for_requests

      simulate_input('#issue-description', "@#{user.name[0...3]}")

      wait_for_requests

      find('.atwho-view .cur').click

      click_button 'Save changes'

      wait_for_requests

      expect(find('.description')).to have_content(user.to_reference)
    end

    it 'opens quick action autocomplete when updating description' do
      find('.js-issuable-edit').click

      find('#issue-description').native.send_keys('/')

      expect(page).to have_selector('.atwho-container')
    end

    it 'opens autocomplete menu when field starts with text' do
      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys('@')
      end

      expect(page).to have_selector('.atwho-container')
    end

    it 'opens autocomplete menu for Issues when field starts with text with item escaping HTML characters' do
      issue_xss_title = 'This will execute alert<img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;'
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
      milestone_xss_title = 'alert milestone &lt;img src=x onerror="alert(\'Hello xss\');" a'
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

    context 'assignees' do
      let(:issue_assignee) { create(:issue, project: project) }
      let(:unassigned_user) { create(:user) }

      before do
        issue_assignee.update(assignees: [user])

        project.add_maintainer(unassigned_user)
      end

      it 'lists users who are currently not assigned to the issue when using /assign' do
        visit project_issue_path(project, issue_assignee)

        note = find('#note-body')
        page.within '.timeline-content-form' do
          note.native.send_keys('/as')
        end

        find('.atwho-view li', text: '/assign')
        note.native.send_keys(:tab)

        wait_for_requests

        expect(find('#at-view-users .atwho-view-ul')).not_to have_content(user.username)
        expect(find('#at-view-users .atwho-view-ul')).to have_content(unassigned_user.username)
      end

      it 'shows dropdown on new issue form' do
        visit new_project_issue_path(project)

        textarea = find('#issue_description')
        textarea.native.send_keys('/ass')
        find('.atwho-view li', text: '/assign')
        textarea.native.send_keys(:tab)

        expect(find('#at-view-users .atwho-view-ul')).to have_content(unassigned_user.username)
        expect(find('#at-view-users .atwho-view-ul')).to have_content(user.username)
      end
    end

    context 'labels' do
      it 'opens autocomplete menu for Labels when field starts with text with item escaping HTML characters' do
        label_xss_title = 'alert label &lt;img src=x onerror="alert(\'Hello xss\');" a'
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
  end

  describe 'when tribute_autocomplete feature flag is on' do
    before do
      stub_feature_flags(tribute_autocomplete: true)

      sign_in(user)
      visit project_issue_path(project, issue)

      wait_for_requests
    end

    it 'updates issue description with GFM reference' do
      find('.js-issuable-edit').click

      wait_for_requests

      simulate_input('#issue-description', "@#{user.name[0...3]}")

      wait_for_requests

      find('.tribute-container .highlight', visible: true).click

      click_button 'Save changes'

      wait_for_requests

      expect(find('.description')).to have_content(user.to_reference)
    end

    it 'opens autocomplete menu when field starts with text' do
      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys('@')
      end

      expect(page).to have_selector('.tribute-container', visible: true)
    end

    it 'opens autocomplete menu for Issues when field starts with text with item escaping HTML characters' do
      issue_xss_title = 'This will execute alert<img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;'
      create(:issue, project: project, title: issue_xss_title)

      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys('#')
      end

      wait_for_requests

      expect(page).to have_selector('.tribute-container', visible: true)

      page.within '.tribute-container ul' do
        expect(page.all('li').first.text).to include(issue_xss_title)
      end
    end

    it 'opens autocomplete menu for Username when field starts with text with item escaping HTML characters' do
      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys('@ev')
      end

      wait_for_requests

      expect(page).to have_selector('.tribute-container', visible: true)

      expect(find('.tribute-container ul', visible: true)).to have_text(user_xss.username)
    end

    it 'opens autocomplete menu for Milestone when field starts with text with item escaping HTML characters' do
      milestone_xss_title = 'alert milestone &lt;img src=x onerror="alert(\'Hello xss\');" a'
      create(:milestone, project: project, title: milestone_xss_title)

      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys('%')
      end

      wait_for_requests

      expect(page).to have_selector('.tribute-container', visible: true)

      expect(find('.tribute-container ul', visible: true)).to have_text('alert milestone')
    end

    it 'selects the first item for assignee dropdowns' do
      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys('@')
      end

      expect(page).to have_selector('.tribute-container', visible: true)

      wait_for_requests

      expect(find('.tribute-container ul', visible: true)).to have_selector('.highlight:first-of-type')
    end

    it 'includes items for assignee dropdowns with non-ASCII characters in name' do
      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys('')
        simulate_input('#note-body', "@#{user.name[0...8]}")
      end

      expect(page).to have_selector('.tribute-container', visible: true)

      wait_for_requests

      expect(find('.tribute-container ul', visible: true)).to have_content(user.name)
    end

    context 'when autocompleting for groups' do
      it 'shows the group when searching for the name of the group' do
        page.within '.timeline-content-form' do
          find('#note-body').native.send_keys('@mygroup')
        end

        expect(find('.tribute-container ul', visible: true)).to have_text('My group')
      end

      it 'does not show the group when searching for the name of the parent of the group' do
        page.within '.timeline-content-form' do
          find('#note-body').native.send_keys('@ancestor')
        end

        expect(find('.tribute-container ul', visible: true)).not_to have_text('My group')
      end
    end

    context 'if a selected value has special characters' do
      it 'wraps the result in double quotes' do
        note = find('#note-body')
        page.within '.timeline-content-form' do
          find('#note-body').native.send_keys('')
          simulate_input('#note-body', "~#{label.title[0]}")
        end

        label_item = find('.tribute-container ul', text: label.title, visible: true)

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

        expect(page).to have_selector('.tribute-container', visible: true)
      end

      it "does not show dropdown when preceded with a special character" do
        note = find('#note-body')
        page.within '.timeline-content-form' do
          note.native.send_keys("@")
        end

        expect(page).to have_selector('.tribute-container', visible: true)

        page.within '.timeline-content-form' do
          note.native.send_keys("@")
        end

        expect(page).not_to have_selector('.tribute-container')
      end

      it "does not throw an error if no labels exist" do
        note = find('#note-body')
        page.within '.timeline-content-form' do
          note.native.send_keys('~')
        end

        expect(page).to have_selector('.tribute-container', visible: false)
      end

      it 'doesn\'t wrap for assignee values' do
        note = find('#note-body')
        page.within '.timeline-content-form' do
          note.native.send_keys("@#{user.username[0]}")
        end

        user_item = find('.tribute-container ul', text: user.username, visible: true)

        expect_to_wrap(false, user_item, note, user.username)
      end

      it 'doesn\'t open autocomplete after non-word character' do
        page.within '.timeline-content-form' do
          find('#note-body').native.send_keys("@#{user.username[0..2]}!")
        end

        expect(page).not_to have_selector('.tribute-container')
      end

      it 'triggers autocomplete after selecting a quick action' do
        note = find('#note-body')
        page.within '.timeline-content-form' do
          note.native.send_keys('/as')
        end

        find('.atwho-view li', text: '/assign')
        note.native.send_keys(:tab)
        note.native.send_keys(:right)

        wait_for_requests

        user_item = find('.tribute-container ul', text: user.username, visible: true)
        expect(user_item).to have_content(user.username)
      end
    end

    context 'assignees' do
      let(:issue_assignee) { create(:issue, project: project) }
      let(:unassigned_user) { create(:user) }

      before do
        issue_assignee.update(assignees: [user])

        project.add_maintainer(unassigned_user)
      end

      it 'lists users who are currently not assigned to the issue when using /assign' do
        visit project_issue_path(project, issue_assignee)

        note = find('#note-body')
        page.within '.timeline-content-form' do
          note.native.send_keys('/as')
        end

        find('.atwho-view li', text: '/assign')
        note.native.send_keys(:tab)
        note.native.send_keys(:right)

        wait_for_requests

        expect(find('.tribute-container ul', visible: true)).not_to have_content(user.username)
        expect(find('.tribute-container ul', visible: true)).to have_content(unassigned_user.username)
      end

      it 'lists users who are currently not assigned to the issue when using /assign on the second line' do
        visit project_issue_path(project, issue_assignee)

        note = find('#note-body')
        page.within '.timeline-content-form' do
          note.native.send_keys('/assign @user2')
          note.native.send_keys(:enter)
          note.native.send_keys('/assign @')
          note.native.send_keys(:right)
        end

        wait_for_requests

        expect(find('.tribute-container ul', visible: true)).not_to have_content(user.username)
        expect(find('.tribute-container ul', visible: true)).to have_content(unassigned_user.username)
      end
    end

    context 'labels' do
      it 'opens autocomplete menu for Labels when field starts with text with item escaping HTML characters' do
        label_xss_title = 'alert label &lt;img src=x onerror="alert(\'Hello xss\');" a'
        create(:label, project: project, title: label_xss_title)

        note = find('#note-body')

        # It should show all the labels on "~".
        type(note, '~')

        wait_for_requests

        expect(find('.tribute-container ul', visible: true).text).to have_content('alert label')
      end

      it 'allows colons when autocompleting scoped labels' do
        create(:label, project: project, title: 'scoped:label')

        note = find('#note-body')
        type(note, '~scoped:')

        wait_for_requests

        expect(find('.tribute-container ul', visible: true).text).to have_content('scoped:label')
      end

      it 'allows colons when autocompleting scoped labels with double colons' do
        create(:label, project: project, title: 'scoped::label')

        note = find('#note-body')
        type(note, '~scoped::')

        wait_for_requests

        expect(find('.tribute-container ul', visible: true).text).to have_content('scoped::label')
      end

      it 'autocompletes multi-word labels' do
        create(:label, project: project, title: 'Accepting merge requests')

        note = find('#note-body')
        type(note, '~Acceptingmerge')

        wait_for_requests

        expect(find('.tribute-container ul', visible: true).text).to have_content('Accepting merge requests')
      end

      it 'only autocompletes the latest label' do
        create(:label, project: project, title: 'documentation')
        create(:label, project: project, title: 'feature')

        note = find('#note-body')
        type(note, '~documentation foo bar ~feat')
        note.native.send_keys(:right)

        wait_for_requests

        expect(find('.tribute-container ul', visible: true).text).to have_content('feature')
        expect(find('.tribute-container ul', visible: true).text).not_to have_content('documentation')
      end

      it 'does not autocomplete labels if no tilde is typed' do
        create(:label, project: project, title: 'documentation')

        note = find('#note-body')
        type(note, 'document')

        wait_for_requests

        expect(page).not_to have_selector('.tribute-container')
      end
    end

    shared_examples 'autocomplete suggestions' do
      it 'suggests objects correctly' do
        page.within '.timeline-content-form' do
          find('#note-body').native.send_keys(object.class.reference_prefix)
        end

        page.within '.tribute-container' do
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

    context 'when other notes are destroyed' do
      let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

      # This is meant to protect against this issue https://gitlab.com/gitlab-org/gitlab/-/issues/228729
      it 'keeps autocomplete key listeners' do
        visit project_issue_path(project, issue)
        note = find('#note-body')

        start_comment_with_emoji(note)

        start_and_cancel_discussion

        note.fill_in(with: '')
        start_comment_with_emoji(note)
        note.native.send_keys(:enter)

        expect(note.value).to eql('Hello :100: ')
      end

      def start_comment_with_emoji(note)
        note.native.send_keys('Hello :10')

        wait_for_requests

        find('.atwho-view li', text: '100')
      end

      def start_and_cancel_discussion
        click_button('Reply...')

        fill_in('note_note', with: 'Whoops!')

        page.accept_alert 'Are you sure you want to cancel creating this comment?' do
          click_button('Cancel')
        end

        wait_for_requests
      end
    end
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
