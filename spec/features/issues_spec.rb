require 'spec_helper'

describe 'Issues', feature: true do
  include SortingHelper

  let(:project) { create(:project) }

  before do
    login_as :user
    user2 = create(:user)

    project.team << [[@user, user2], :developer]
  end

  describe 'Edit issue' do
    let!(:issue) do
      create(:issue,
             author: @user,
             assignee: @user,
             project: project)
    end

    before do
      visit edit_namespace_project_issue_path(project.namespace, project, issue)
      find('.js-zen-enter').click
    end

    it 'should open new issue popup' do
      expect(page).to have_content("Issue ##{issue.iid}")
    end

    describe 'fill in' do
      before do
        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'
      end
    end
  end

  describe 'Editing issue assignee' do
    let!(:issue) do
      create(:issue,
             author: @user,
             assignee: @user,
             project: project)
    end

    it 'allows user to select unassigned', js: true do
      visit edit_namespace_project_issue_path(project.namespace, project, issue)

      expect(page).to have_content "Assignee #{@user.name}"

      first('#s2id_issue_assignee_id').click
      sleep 2 # wait for ajax stuff to complete
      first('.user-result').click

      click_button 'Save changes'

      page.within('.assignee') do
        expect(page).to have_content 'No assignee - assign yourself'
      end

      expect(issue.reload.assignee).to be_nil
    end
  end

  describe 'due date', js: true do
    context 'on new form' do
      before do
        visit new_namespace_project_issue_path(project.namespace, project)
      end

      it 'should save with due date' do
        date = Date.today.at_beginning_of_month

        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'
        find('#issuable-due-date').click

        page.within '.ui-datepicker' do
          click_link date.day
        end

        expect(find('#issuable-due-date').value).to eq date.to_s

        click_button 'Submit issue'

        page.within '.issuable-sidebar' do
          expect(page).to have_content date.to_s(:medium)
        end
      end
    end

    context 'on edit form' do
      let(:issue) { create(:issue, author: @user, project: project, due_date: Date.today.at_beginning_of_month.to_s) }

      before do
        visit edit_namespace_project_issue_path(project.namespace, project, issue)
      end

      it 'should save with due date' do
        date = Date.today.at_beginning_of_month

        expect(find('#issuable-due-date').value).to eq date.to_s

        date = date.tomorrow

        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'
        find('#issuable-due-date').click

        page.within '.ui-datepicker' do
          click_link date.day
        end

        expect(find('#issuable-due-date').value).to eq date.to_s

        click_button 'Save changes'

        page.within '.issuable-sidebar' do
          expect(page).to have_content date.to_s(:medium)
        end
      end
    end
  end

  describe 'Issue info' do
    it 'excludes award_emoji from comment count' do
      issue = create(:issue, author: @user, assignee: @user, project: project, title: 'foobar')
      create(:award_emoji, awardable: issue)

      visit namespace_project_issues_path(project.namespace, project, assignee_id: @user.id)

      expect(page).to have_content 'foobar'
      expect(page.all('.issue-no-comments').first.text).to eq "0"
    end
  end

  describe 'Filter issue' do
    before do
      ['foobar', 'barbaz', 'gitlab'].each do |title|
        create(:issue,
               author: @user,
               assignee: @user,
               project: project,
               title: title)
      end

      @issue = Issue.find_by(title: 'foobar')
      @issue.milestone = create(:milestone, project: project)
      @issue.assignee = nil
      @issue.save
    end

    let(:issue) { @issue }

    it 'should allow filtering by issues with no specified assignee' do
      visit namespace_project_issues_path(project.namespace, project, assignee_id: IssuableFinder::NONE)

      expect(page).to have_content 'foobar'
      expect(page).not_to have_content 'barbaz'
      expect(page).not_to have_content 'gitlab'
    end

    it 'should allow filtering by a specified assignee' do
      visit namespace_project_issues_path(project.namespace, project, assignee_id: @user.id)

      expect(page).not_to have_content 'foobar'
      expect(page).to have_content 'barbaz'
      expect(page).to have_content 'gitlab'
    end
  end

  describe 'filter issue' do
    titles = %w[foo bar baz]
    titles.each_with_index do |title, index|
      let!(title.to_sym) do
        create(:issue, title: title,
                       project: project,
                       created_at: Time.now - (index * 60))
      end
    end
    let(:newer_due_milestone) { create(:milestone, due_date: '2013-12-11') }
    let(:later_due_milestone) { create(:milestone, due_date: '2013-12-12') }

    it 'sorts by newest' do
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_recently_created)

      expect(first_issue).to include('baz')
      expect(last_issue).to include('foo')
    end

    it 'sorts by oldest' do
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_oldest_created)

      expect(first_issue).to include('foo')
      expect(last_issue).to include('baz')
    end

    it 'sorts by most recently updated' do
      baz.updated_at = Time.now + 100
      baz.save
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_recently_updated)

      expect(first_issue).to include('baz')
    end

    it 'sorts by least recently updated' do
      baz.updated_at = Time.now - 100
      baz.save
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_oldest_updated)

      expect(first_issue).to include('baz')
    end

    describe 'sorting by due date' do
      before do
        foo.update(due_date: 1.day.from_now)
        bar.update(due_date: 6.days.from_now)
      end

      it 'sorts by recently due date' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_due_date_soon)

        expect(first_issue).to include('foo')
      end

      it 'sorts by least recently due date' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_due_date_later)

        expect(first_issue).to include('bar')
      end

      it 'sorts by least recently due date by excluding nil due dates' do
        bar.update(due_date: nil)

        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_due_date_later)

        expect(first_issue).to include('foo')
      end

      context 'with a filter on labels' do
        let(:label) { create(:label, project: project) }
        before { create(:label_link, label: label, target: foo) }

        it 'sorts by least recently due date by excluding nil due dates' do
          bar.update(due_date: nil)

          visit namespace_project_issues_path(project.namespace, project, label_names: [label.name], sort: sort_value_due_date_later)

          expect(first_issue).to include('foo')
        end
      end
    end

    describe 'filtering by due date' do
      before do
        foo.update(due_date: 1.day.from_now)
        bar.update(due_date: 6.days.from_now)
      end

      it 'filters by none' do
        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::NoDueDate.name)

        expect(page).not_to have_content('foo')
        expect(page).not_to have_content('bar')
        expect(page).to have_content('baz')
      end

      it 'filters by any' do
        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::AnyDueDate.name)

        expect(page).to have_content('foo')
        expect(page).to have_content('bar')
        expect(page).to have_content('baz')
      end

      it 'filters by due this week' do
        foo.update(due_date: Date.today.beginning_of_week + 2.days)
        bar.update(due_date: Date.today.end_of_week)
        baz.update(due_date: Date.today - 8.days)

        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::DueThisWeek.name)

        expect(page).to have_content('foo')
        expect(page).to have_content('bar')
        expect(page).not_to have_content('baz')
      end

      it 'filters by due this month' do
        foo.update(due_date: Date.today.beginning_of_month + 2.days)
        bar.update(due_date: Date.today.end_of_month)
        baz.update(due_date: Date.today - 50.days)

        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::DueThisMonth.name)

        expect(page).to have_content('foo')
        expect(page).to have_content('bar')
        expect(page).not_to have_content('baz')
      end

      it 'filters by overdue' do
        foo.update(due_date: Date.today + 2.days)
        bar.update(due_date: Date.today + 20.days)
        baz.update(due_date: Date.yesterday)

        visit namespace_project_issues_path(project.namespace, project, due_date: Issue::Overdue.name)

        expect(page).not_to have_content('foo')
        expect(page).not_to have_content('bar')
        expect(page).to have_content('baz')
      end
    end

    describe 'sorting by milestone' do
      before do
        foo.milestone = newer_due_milestone
        foo.save
        bar.milestone = later_due_milestone
        bar.save
      end

      it 'sorts by recently due milestone' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_milestone_soon)

        expect(first_issue).to include('foo')
        expect(last_issue).to include('baz')
      end

      it 'sorts by least recently due milestone' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_milestone_later)

        expect(first_issue).to include('bar')
        expect(last_issue).to include('baz')
      end
    end

    describe 'combine filter and sort' do
      let(:user2) { create(:user) }

      before do
        foo.assignee = user2
        foo.save
        bar.assignee = user2
        bar.save
      end

      it 'sorts with a filter applied' do
        visit namespace_project_issues_path(project.namespace, project,
                                            sort: sort_value_oldest_created,
                                            assignee_id: user2.id)

        expect(first_issue).to include('foo')
        expect(last_issue).to include('bar')
        expect(page).not_to have_content 'baz'
      end
    end
  end

  describe 'update assignee from issue#show' do
    let(:issue) { create(:issue, project: project, author: @user, assignee: @user) }

    context 'by authorized user' do
      it 'allows user to select unassigned', js: true do
        visit namespace_project_issue_path(project.namespace, project, issue)

        page.within('.assignee') do
          expect(page).to have_content "#{@user.name}"

          click_link 'Edit'
          click_link 'Unassigned'
          expect(page).to have_content 'No assignee'
        end

        expect(issue.reload.assignee).to be_nil
      end

      it 'allows user to select an assignee', js: true do
        issue2 = create(:issue, project: project, author: @user)
        visit namespace_project_issue_path(project.namespace, project, issue2)

        page.within('.assignee') do
          expect(page).to have_content "No assignee"
        end

        page.within '.assignee' do
          click_link 'Edit'
        end

        page.within '.dropdown-menu-user' do
          click_link @user.name
        end

        page.within('.assignee') do
          expect(page).to have_content @user.name
        end
      end

      it 'allows user to unselect themselves', js: true do
        issue2 = create(:issue, project: project, author: @user)
        visit namespace_project_issue_path(project.namespace, project, issue2)

        page.within '.assignee' do
          click_link 'Edit'
          click_link @user.name

          page.within '.value' do
            expect(page).to have_content @user.name
          end

          click_link 'Edit'
          click_link @user.name

          page.within '.value' do
            expect(page).to have_content "No assignee"
          end
        end
      end
    end

    context 'by unauthorized user' do
      let(:guest) { create(:user) }

      before do
        project.team << [[guest], :guest]
      end

      it 'shows assignee text', js: true do
        logout
        login_with guest

        visit namespace_project_issue_path(project.namespace, project, issue)
        expect(page).to have_content issue.assignee.name
      end
    end
  end

  describe 'update weight from issue#show', js: true do
    let!(:issue) { create(:issue, project: project) }

    before do
      visit namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'should allow user to update to a weight' do
      page.within('.weight') do
        expect(page).to have_content "None"
        click_link 'Edit'

        find('.dropdown-content a', text: '1').click

        page.within('.value') do
          expect(page).to have_content "1"
        end
      end
    end
  end

  describe 'update milestone from issue#show' do
    let!(:issue) { create(:issue, project: project, author: @user) }
    let!(:milestone) { create(:milestone, project: project) }

    context 'by authorized user' do
      it 'allows user to select unassigned', js: true do
        visit namespace_project_issue_path(project.namespace, project, issue)

        page.within('.milestone') do
          expect(page).to have_content "None"
        end

        find('.block.milestone .edit-link').click
        sleep 2 # wait for ajax stuff to complete
        first('.dropdown-content li').click
        sleep 2
        page.within('.milestone') do
          expect(page).to have_content 'None'
        end

        expect(issue.reload.milestone).to be_nil
      end

      it 'allows user to de-select milestone', js: true do
        visit namespace_project_issue_path(project.namespace, project, issue)

        page.within('.milestone') do
          click_link 'Edit'
          click_link milestone.title

          page.within '.value' do
            expect(page).to have_content milestone.title
          end

          click_link 'Edit'
          click_link milestone.title

          page.within '.value' do
            expect(page).to have_content 'None'
          end
        end
      end
    end

    context 'by unauthorized user' do
      let(:guest) { create(:user) }

      before do
        project.team << [guest, :guest]
        issue.milestone = milestone
        issue.save
      end

      it 'shows milestone text', js: true do
        logout
        login_with guest

        visit namespace_project_issue_path(project.namespace, project, issue)
        expect(page).to have_content milestone.title
      end
    end

    describe 'removing assignee' do
      let(:user2) { create(:user) }

      before do
        issue.assignee = user2
        issue.save
      end
    end
  end

  describe 'new issue' do
    context 'dropzone upload file', js: true do
      before do
        visit new_namespace_project_issue_path(project.namespace, project)
      end

      it 'should upload file when dragging into textarea' do
        drop_in_dropzone test_image_file

        # Wait for the file to upload
        sleep 1

        expect(page.find_field("issue_description").value).to have_content 'banana_sample'
      end
    end
  end

  describe 'due date' do
    context 'update due on issue#show', js: true do
      let(:issue) { create(:issue, project: project, author: @user, assignee: @user) }

      before do
        visit namespace_project_issue_path(project.namespace, project, issue)
      end

      it 'should add due date to issue' do
        page.within '.due_date' do
          click_link 'Edit'

          page.within '.ui-datepicker-calendar' do
            first('.ui-state-default').click
          end

          expect(page).to have_no_content 'None'
        end
      end

      it 'should remove due date from issue' do
        page.within '.due_date' do
          click_link 'Edit'

          page.within '.ui-datepicker-calendar' do
            first('.ui-state-default').click
          end

          expect(page).to have_no_content 'No due date'

          click_link 'remove due date'
          expect(page).to have_content 'No due date'
        end
      end
    end
  end

  def first_issue
    page.all('ul.issues-list > li').first.text
  end

  def last_issue
    page.all('ul.issues-list > li').last.text
  end

  def drop_in_dropzone(file_path)
    # Generate a fake input selector
    page.execute_script <<-JS
      var fakeFileInput = window.$('<input/>').attr(
        {id: 'fakeFileInput', type: 'file'}
      ).appendTo('body');
    JS
    # Attach the file to the fake input selector with Capybara
    attach_file("fakeFileInput", file_path)
    # Add the file to a fileList array and trigger the fake drop event
    page.execute_script <<-JS
      var fileList = [$('#fakeFileInput')[0].files[0]];
      var e = jQuery.Event('drop', { dataTransfer : { files : fileList } });
      $('.div-dropzone')[0].dropzone.listeners[0].events.drop(e);
    JS
  end

  def test_image_file
    File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif')
  end
end
