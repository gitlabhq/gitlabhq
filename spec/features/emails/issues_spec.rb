# frozen_string_literal: true

require "spec_helper"

RSpec.describe "E-Mails > Issues", :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project_empty_repo, :public, name: 'Long Earth') }
  let_it_be(:author) { create(:user, username: 'author', name: 'Sally Linsay') }
  let_it_be(:current_user) { create(:user, username: 'current_user', name: 'Shi-mi') }

  before do
    project.add_developer(current_user)
    sign_in(current_user)
  end

  describe 'assignees' do
    let_it_be(:assignee) { create(:user, username: 'assignee', name: 'Joshua Valienté') }
    let_it_be(:issue_without_assignee) { create(:issue, project: project, author: author, title: 'No milk today!') }

    let_it_be(:issue_with_assignee) do
      create(
        :issue, project: project, author: author, assignees: [assignee],
        title: 'All your base are belong to us')
    end

    it 'sends confirmation e-mail for assigning' do
      synchronous_notifications
      expect(Notify).to receive(:reassigned_issue_email)
        .with(author.id, issue_without_assignee.id, [], current_user.id, nil)
        .once
        .and_call_original
      expect(Notify).to receive(:reassigned_issue_email)
        .with(assignee.id, issue_without_assignee.id, [], current_user.id, NotificationReason::ASSIGNED)
        .once
        .and_call_original

      visit issue_path(issue_without_assignee)
      assign_to(assignee)

      expect(find('#notes-list')).to have_text("Shi-mi assigned to @assignee just now")
    end

    it 'sends confirmation e-mail for reassigning' do
      synchronous_notifications
      expect(Notify).to receive(:reassigned_issue_email)
        .with(author.id, issue_with_assignee.id, [assignee.id], current_user.id, NotificationReason::ASSIGNED)
        .once
        .and_call_original
      expect(Notify).to receive(:reassigned_issue_email)
        .with(assignee.id, issue_with_assignee.id, [assignee.id], current_user.id, nil)
        .once
        .and_call_original

      visit issue_path(issue_with_assignee)
      assign_to(author)

      expect(find('#notes-list')).to have_text("Shi-mi assigned to @author and unassigned @assignee just now")
    end

    it 'sends confirmation e-mail for unassigning' do
      synchronous_notifications
      expect(Notify).to receive(:reassigned_issue_email)
        .with(author.id, issue_with_assignee.id, [assignee.id], current_user.id, nil)
        .once
        .and_call_original
      expect(Notify).to receive(:reassigned_issue_email)
        .with(assignee.id, issue_with_assignee.id, [assignee.id], current_user.id, nil)
        .once
        .and_call_original

      visit issue_path(issue_with_assignee)
      quick_action('/unassign')

      expect(find('#notes-list')).to have_text("Shi-mi unassigned @assignee just now")
    end
  end

  describe 'closing' do
    let_it_be(:issue) { create(:issue, project: project, author: author, title: 'Public Holiday') }

    it 'sends confirmation e-mail for closing' do
      synchronous_notifications
      expect(Notify).to receive(:closed_issue_email)
        .with(author.id, issue.id, current_user.id, { closed_via: nil, reason: nil })
        .once
        .and_call_original

      visit issue_path(issue)
      quick_action("/close")

      expect(find('#notes-list')).to have_text("Shi-mi closed just now")
    end
  end

  private

  def assign_to(user)
    quick_action("/assign @#{user.username}")
  end

  def quick_action(command)
    fill_in 'note[note]', with: command
    click_button 'Comment'
  end

  def synchronous_notifications
    expect_next_instance_of(NotificationService) do |service|
      expect(service).to receive(:async).and_return(service)
    end
  end
end
