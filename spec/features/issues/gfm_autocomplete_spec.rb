# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GFM autocomplete', :js, feature_category: :text_editors do
  include Features::AutocompleteHelpers

  let_it_be(:user) { create(:user, name: '💃speciąl someone💃', username: 'someone.special') }
  let_it_be(:user2) { create(:user, name: 'Marge Simpson', username: 'msimpson') }

  let_it_be(:group) { create(:group, maintainers: [user, user2]) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project, assignees: [user]) }
  let_it_be(:label) { create(:label, project: project, title: 'special+') }
  let_it_be(:label_scoped) { create(:label, project: project, title: 'scoped::label') }
  let_it_be(:label_with_spaces) { create(:label, project: project, title: 'Accepting merge requests') }
  let_it_be(:snippet) { create(:project_snippet, project: project, title: 'code snippet') }

  let_it_be(:user_xss_title) { 'eve <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;' }
  let_it_be(:user_xss) { create(:user, name: user_xss_title, username: 'xss.user', maintainer_of: group) }
  let_it_be(:label_xss_title) { 'alert label &lt;img src=x onerror="alert(\'Hello xss\');" a' }
  let_it_be(:label_xss) { create(:label, project: project, title: label_xss_title) }

  describe 'new issue page' do
    before do
      sign_in(user)
      visit new_project_issue_path(project)

      wait_for_requests
    end

    it 'allows quick actions' do
      fill_in 'Description', with: '/'

      expect(find_autocomplete_menu).to be_visible
    end
  end

  describe 'issue description' do
    let(:issue_to_edit) { create(:issue, project: project) }

    before do
      sign_in(user)
      visit project_issue_path(project, issue_to_edit)

      wait_for_requests
    end

    it 'updates with GFM reference' do
      click_button 'Edit title and description'

      wait_for_requests

      fill_in 'Description', with: "@#{user.name[0...3]}"

      wait_for_requests

      find_highlighted_autocomplete_item.click

      click_button 'Save changes'

      wait_for_requests

      expect(find('.description')).to have_text(user.to_reference)
    end

    it 'allows quick actions' do
      click_button 'Edit title and description'

      fill_in 'Description', with: '/'

      expect(find_autocomplete_menu).to be_visible
    end
  end

  describe 'issue comment' do
    before do
      sign_in(user)
      visit project_issue_path(project, issue)

      wait_for_requests
    end

    describe 'triggering autocomplete' do
      it 'only opens autocomplete menu when trigger character is after whitespace', :aggregate_failures do
        fill_in 'Comment', with: 'testing@'
        expect(page).not_to have_css('.atwho-view')

        fill_in 'Comment', with: '@@'
        expect(page).not_to have_css('.atwho-view')

        fill_in 'Comment', with: "@#{user.username[0..2]}!"
        expect(page).not_to have_css('.atwho-view')

        fill_in 'Comment', with: "hello:#{user.username[0..2]}"
        expect(page).not_to have_css('.atwho-view')

        fill_in 'Comment', with: '7:'
        expect(page).not_to have_css('.atwho-view')

        fill_in 'Comment', with: 'w:'
        expect(page).not_to have_css('.atwho-view')

        fill_in 'Comment', with: 'Ё:'
        expect(page).not_to have_css('.atwho-view')

        fill_in 'Comment', with: "test\n\n@"
        expect(find_autocomplete_menu).to be_visible
      end

      it 'does not open label autocomplete menu after strikethrough', :aggregate_failures do
        fill_in 'Comment', with: "~~"
        expect(page).not_to have_css('.atwho-view')

        fill_in 'Comment', with: "~~gone~~"
        expect(page).not_to have_css('.atwho-view')

        fill_in 'Comment', with: "~"
        expect(find_autocomplete_menu).to be_visible

        fill_in 'Comment', with: "test\n\n~"
        expect(find_autocomplete_menu).to be_visible
      end
    end

    context 'xss checks' do
      it 'opens autocomplete menu for Issues when field starts with text with item escaping HTML characters' do
        issue_xss_title = 'This will execute alert<img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;'
        create(:issue, project: project, title: issue_xss_title)

        fill_in 'Comment', with: '#'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text(issue_xss_title)
      end

      it 'opens autocomplete menu for Username when field starts with text with item escaping HTML characters' do
        fill_in 'Comment', with: '@ev'

        wait_for_requests

        expect(find_highlighted_autocomplete_item).to have_text(user_xss.username)
      end

      it 'opens autocomplete menu for Milestone when field starts with text with item escaping HTML characters' do
        milestone_xss_title = 'alert milestone &lt;img src=x onerror="alert(\'Hello xss\');" a'
        create(:milestone, project: project, title: milestone_xss_title)

        fill_in 'Comment', with: '%'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('alert milestone')
      end

      it 'opens autocomplete menu for Labels when field starts with text with item escaping HTML characters' do
        fill_in 'Comment', with: '~'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('alert label')
      end
    end

    describe 'autocomplete highlighting' do
      it 'auto-selects the first item when there is a query, and only for assignees with no query', :aggregate_failures do
        fill_in 'Comment', with: ':'
        wait_for_requests
        expect(find_autocomplete_menu).not_to have_css('.cur')

        fill_in 'Comment', with: ':1'
        wait_for_requests
        expect(find_autocomplete_menu).to have_css('.cur:first-of-type')

        fill_in 'Comment', with: '@'
        wait_for_requests
        expect(find_autocomplete_menu).to have_css('.cur:first-of-type')
      end
    end

    context 'autocomplete user mentions' do
      it 'does not wrap with quotes for assignee values' do
        fill_in 'Comment', with: "@#{user.username}"

        find_highlighted_autocomplete_item.click

        expect(find_field('Comment').value).to have_text("@#{user.username}")
      end

      it 'includes items for assignee dropdowns with non-ASCII characters in name' do
        fill_in 'Comment', with: "@#{user.name[0...8]}"

        wait_for_requests

        expect(find_autocomplete_menu).to have_text(user.name)
      end

      it 'searches across full name for assignees' do
        fill_in 'Comment', with: '@speciąlsome'

        wait_for_requests

        expect(find_highlighted_autocomplete_item).to have_text(user.name)
      end

      it 'shows names that start with the query as the top result' do
        fill_in 'Comment', with: '@mar'

        wait_for_requests

        expect(find_highlighted_autocomplete_item).to have_text(user2.name)
      end

      it 'shows usernames that start with the query as the top result' do
        fill_in 'Comment', with: '@msi'

        wait_for_requests

        expect(find_highlighted_autocomplete_item).to have_text(user2.name)
      end

      # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/321925
      it 'shows username when pasting then pressing Enter' do
        fill_in 'Comment', with: "@#{user.username}\n"

        expect(find_field('Comment').value).to have_text "@#{user.username}"
      end

      it 'does not show `@undefined` when pressing `@` then Enter' do
        fill_in 'Comment', with: "@\n"

        expect(find_field('Comment').value).to have_text '@'
        expect(find_field('Comment').value).not_to have_text '@undefined'
      end

      context 'when /assign quick action is selected' do
        it 'triggers user autocomplete and lists users who are currently not assigned to the issue' do
          fill_in 'Comment', with: '/as'

          find_highlighted_autocomplete_item.click

          expect(find_autocomplete_menu).not_to have_text(user.username)
          expect(find_autocomplete_menu).to have_text(user2.username)
        end
      end
    end

    context 'autocomplete wiki pages' do
      let_it_be(:wiki_page1) { create(:wiki_page, project: project, title: 'Home') }
      let_it_be(:wiki_page2) { create(:wiki_page, project: project, title: 'How to use GitLab') }

      it 'shows wiki pages in the autocomplete menu' do
        fill_in 'Comment', with: '[[ho'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('Home')
        expect(find_autocomplete_menu).to have_text('How to use GitLab (How-to-use-GitLab)')

        send_keys [:arrow_down, :enter]

        expect(find_field('Comment').value).to have_text('[[How to use GitLab|How-to-use-GitLab]]')
      end
    end

    context 'if a selected value has special characters' do
      it 'wraps the result in double quotes' do
        fill_in 'Comment', with: "~#{label.title[0..2]}"

        find_highlighted_autocomplete_item.click

        expect(find_field('Comment').value).to have_text("~\"#{label.title}\"")
      end

      it 'doesn\'t wrap for emoji values' do
        fill_in 'Comment', with: ':cartwheel_'

        find_highlighted_autocomplete_item.click

        expect(find_field('Comment').value).to have_text('cartwheel_tone1')
      end
    end

    context 'quick actions' do
      it 'does not limit quick actions autocomplete list to 5' do
        fill_in 'Comment', with: '/'

        expect(find_autocomplete_menu).to have_css('li', minimum: 6)
      end
    end

    context 'labels' do
      it 'allows colons when autocompleting scoped labels' do
        fill_in 'Comment', with: '~scoped:'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('scoped::label')
      end

      it 'allows spaces when autocompleting multi-word labels' do
        fill_in 'Comment', with: '~Accepting merge'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('Accepting merge requests')
      end

      it 'only autocompletes the last label' do
        fill_in 'Comment', with: '~scoped:: foo bar ~Accepting merge'

        wait_for_requests

        expect(find_autocomplete_menu).to have_text('Accepting merge requests')
      end

      it 'does not autocomplete labels if no tilde is typed' do
        fill_in 'Comment', with: 'Accepting merge'

        wait_for_requests

        expect(page).not_to have_css('.atwho-view')
      end
    end

    context 'when other notes are destroyed' do
      let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

      # This is meant to protect against this issue https://gitlab.com/gitlab-org/gitlab/-/issues/228729
      it 'keeps autocomplete key listeners' do
        note = find_field('Comment')

        start_comment_with_emoji(note, '.atwho-view li')

        start_and_cancel_discussion

        note.fill_in(with: '')
        start_comment_with_emoji(note, '.atwho-view li')
        note.native.send_keys(:enter)

        expect(note.value).to eql('Hello :100: ')
      end
    end

    shared_examples 'autocomplete suggestions' do
      it 'suggests objects correctly' do
        fill_in 'Comment', with: object.class.reference_prefix

        find_autocomplete_menu.find('li', text: object.title).click

        expect(find_field('Comment').value).to have_text(expected_body)
      end
    end

    context 'issues' do
      let_it_be(:issue_99) { create(:issue, project: project, title: 'gitlab issue', iid: 99) }
      let_it_be(:issue_990) { create(:issue, project: project, title: 'other issue', iid: 990) }

      it_behaves_like 'autocomplete suggestions' do
        let(:object) { issue }
        let(:expected_body) { object.to_reference }
      end

      shared_examples 'searching issue autocomplete' do
        it 'supports matching by iid' do
          fill_in 'Comment', with: '#99'

          page.within(find_autocomplete_menu) do
            expect(page).to have_selector('li', count: 2)
            expect(page).to have_selector('li', text: 'gitlab issue')
            expect(page).to have_selector('li', text: 'other issue')
          end
        end

        it 'supports matching by title' do
          fill_in 'Comment', with: '#gitlab'

          page.within(find_autocomplete_menu) do
            expect(page).to have_selector('li', count: 1)
            expect(page).to have_selector('li', text: 'gitlab issue')
          end
        end
      end

      it_behaves_like 'searching issue autocomplete'
    end

    context 'merge requests' do
      let(:object) { create(:merge_request, source_project: project) }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'project snippets' do
      let!(:object) { snippet }
      let(:expected_body) { object.to_reference }

      it_behaves_like 'autocomplete suggestions'
    end

    context 'milestone' do
      let_it_be(:milestone_expired) { create(:milestone, project: project, due_date: 5.days.ago) }
      let_it_be(:milestone_no_duedate) { create(:milestone, project: project, title: 'Foo - No due date') }
      let_it_be(:milestone1) { create(:milestone, project: project, title: 'Milestone-1', due_date: 20.days.from_now) }
      let_it_be(:milestone2) { create(:milestone, project: project, title: 'Milestone-2', due_date: 15.days.from_now) }
      let_it_be(:milestone3) { create(:milestone, project: project, title: 'Milestone-3', due_date: 10.days.from_now) }

      before do
        fill_in 'Comment', with: '/milestone %'

        wait_for_requests
      end

      it 'shows milestons list in the autocomplete menu' do
        page.within(find_autocomplete_menu) do
          expect(page).to have_selector('li', count: 5)
        end
      end

      it 'shows expired milestone at the bottom of the list' do
        page.within(find_autocomplete_menu) do
          expect(page.find('li:last-child')).to have_content milestone_expired.title
        end
      end

      it 'shows milestone due earliest at the top of the list' do
        page.within(find_autocomplete_menu) do
          aggregate_failures do
            expect(page.all('li')[0]).to have_content milestone3.title
            expect(page.all('li')[1]).to have_content milestone2.title
            expect(page.all('li')[2]).to have_content milestone1.title
            expect(page.all('li')[3]).to have_content milestone_no_duedate.title
          end
        end
      end
    end

    context 'contact' do
      let_it_be(:contacts) { create_list(:contact, 2, group: group) }

      before do
        fill_in 'Comment', with: '/add_contacts [contact:'

        wait_for_requests
      end

      it 'shows contacts list in the autocomplete menu' do
        page.within(find_autocomplete_menu) do
          expect(page).to have_selector('li', count: 2)
        end
      end

      it 'shows all contacts' do
        page.within(find_autocomplete_menu) do
          expected_data = contacts.map { |c| "#{c.first_name} #{c.last_name} #{c.email}" }

          expect(page.all('li').map(&:text)).to match_array(expected_data)
        end
      end
    end

    context 'when typing enter for autocomplete in a markdown list' do
      it 'does not create a new list item' do
        fill_in 'Comment', with: "- @#{user.username}\n"

        expect(find_field('Comment').value).to eq "- @#{user.username}\n"
      end
    end
  end

  private

  def start_comment_with_emoji(note, selector)
    note.native.send_keys('Hello :10')

    wait_for_requests

    find(selector, text: '100')
  end

  def start_and_cancel_discussion
    fill_in('Reply to comment', with: 'Whoops!')
    click_button('Cancel')

    page.within('.modal') do
      click_button('Discard changes', match: :first)
    end

    wait_for_requests
  end
end
