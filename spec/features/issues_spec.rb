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
      click_link "Edit"
    end

    it 'should open new issue popup' do
      expect(page).to have_content("Issue ##{issue.iid}")
    end

    describe 'fill in' do
      before do
        fill_in 'issue_title', with: 'bug 345'
        fill_in 'issue_description', with: 'bug description'
      end

      it 'does not change issue count' do
        expect { click_button 'Save changes' }.to_not change { Issue.count }
      end

      it 'should update issue fields' do
        click_button 'Save changes'

        expect(page).to have_content @user.name
        expect(page).to have_content 'bug 345'
        expect(page).to have_content project.name
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

    it 'allows user to select unasigned', js: true do
      visit edit_namespace_project_issue_path(project.namespace, project, issue)

      expect(page).to have_content "Assignee #{@user.name}"

      first('#s2id_issue_assignee_id').click
      sleep 2 # wait for ajax stuff to complete
      first('.user-result').click

      click_button 'Save changes'

      page.within('.assignee') do
        expect(page).to have_content 'None'
      end

      expect(issue.reload.assignee).to be_nil
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
    titles = ['foo','bar','baz']
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

    describe 'sorting by milestone' do
      before :each do
        foo.milestone = newer_due_milestone
        foo.save
        bar.milestone = later_due_milestone
        bar.save
      end

      it 'sorts by recently due milestone' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_milestone_soon)

        expect(first_issue).to include('foo')
      end

      it 'sorts by least recently due milestone' do
        visit namespace_project_issues_path(project.namespace, project, sort: sort_value_milestone_later)

        expect(first_issue).to include('bar')
      end
    end

    describe 'combine filter and sort' do
      let(:user2) { create(:user) }

      before :each do
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
    let(:issue) { create(:issue, project: project, author: @user) }

    context 'by autorized user' do

      it 'with dropdown menu' do
        visit namespace_project_issue_path(project.namespace, project, issue)

        find('.issuable-sidebar #issue_assignee_id').
          set project.team.members.first.id
        click_button 'Update Issue'

        expect(page).to have_content 'Assignee'
        has_select?('issue_assignee_id',
                    selected: project.team.members.first.name)
      end
    end

    context 'by unauthorized user' do

      let(:guest) { create(:user) }

      before :each do
        project.team << [[guest], :guest]
        issue.assignee = @user
        issue.save
      end

      it 'shows assignee text', js: true do
        logout
        login_with guest

        visit namespace_project_issue_path(project.namespace, project, issue)
        expect(page).to have_content issue.assignee.name
      end
    end
  end

  describe 'update milestone from issue#show' do
    let!(:issue) { create(:issue, project: project, author: @user) }
    let!(:milestone) { create(:milestone, project: project) }

    context 'by authorized user' do

      it 'with dropdown menu' do
        visit namespace_project_issue_path(project.namespace, project, issue)

        find('.issuable-sidebar').
          select(milestone.title, from: 'issue_milestone_id')
        click_button 'Update Issue'

        expect(page).to have_content "Milestone changed to #{milestone.title}"

        page.within('.milestone') do
          expect(page).to have_content milestone.title
        end

        has_select?('issue_assignee_id', selected: milestone.title)
      end
    end

    context 'by unauthorized user' do
      let(:guest) { create(:user) }

      before :each do
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

      before :each do
        issue.assignee = user2
        issue.save
      end

      it 'allows user to remove assignee', js: true do
        visit namespace_project_issue_path(project.namespace, project, issue)

        page.within('.assignee') do
          expect(page).to have_content user2.name
        end

        find('.assignee .edit-link').click
        sleep 2 # wait for ajax stuff to complete
        first('.user-result').click

        page.within('.assignee') do
          expect(page).to have_content 'None'
        end

        sleep 2 # wait for ajax stuff to complete
        expect(issue.reload.assignee).to be_nil
      end
    end
  end

  def first_issue
    page.all('ul.issues-list > li').first.text
  end

  def last_issue
    page.all('ul.issues-list > li').last.text
  end
end
