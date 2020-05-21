# frozen_string_literal: true

require "spec_helper"

describe "User views issue" do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project, description: "# Description header", author: user) }

  before do
    project.add_developer(user)
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  it { expect(page).to have_header_with_correct_id_and_link(1, "Description header", "description-header") }

  it 'shows the merge request and issue actions', :aggregate_failures do
    expect(page).to have_link('New issue')
    expect(page).to have_button('Create merge request')
    expect(page).to have_link('Close issue')
  end

  context 'when the project is archived' do
    let(:project) { create(:project, :public, :archived) }

    it 'hides the merge request and issue actions', :aggregate_failures do
      expect(page).not_to have_link('New issue')
      expect(page).not_to have_button('Create merge request')
      expect(page).not_to have_link('Close issue')
    end
  end

  describe 'user status' do
    subject { visit(project_issue_path(project, issue)) }

    context 'when showing status of the author of the issue' do
      it_behaves_like 'showing user status' do
        let(:user_with_status) { issue.author }
      end
    end

    context 'when showing status of a user who commented on an issue', :js do
      let!(:note) { create(:note, noteable: issue, project: project, author: user_with_status) }

      it_behaves_like 'showing user status' do
        let(:user_with_status) { create(:user) }
      end
    end

    context 'when status message has an emoji', :js do
      let(:message) { 'My status with an emoji' }
      let(:message_emoji) { 'basketball' }

      let!(:note) { create(:note, noteable: issue, project: project, author: user) }
      let!(:status) { create(:user_status, user: user, emoji: 'smirk', message: "#{message} :#{message_emoji}:") }

      it 'correctly renders the emoji' do
        tooltip_span = page.first(".user-status-emoji[title^='#{message}']")

        tooltip_span.hover

        tooltip = page.find('.tooltip .tooltip-inner')

        page.within(tooltip) do
          expect(page).to have_emoji(message_emoji)
        end
      end
    end
  end
end
