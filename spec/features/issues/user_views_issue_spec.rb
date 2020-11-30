# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views issue" do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project, description: "# Description header\n\n**Lorem** _ipsum_ dolor sit [amet](https://example.com)", author: user) }
  let_it_be(:note) { create(:note, noteable: issue, project: project, author: user) }

  before_all do
    project.add_developer(user)
  end

  before do
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  it { expect(page).to have_header_with_correct_id_and_link(1, "Description header", "description-header") }

  it_behaves_like 'page meta description', ' Description header Lorem ipsum dolor sit amet'

  it 'shows the merge request and issue actions', :js, :aggregate_failures do
    click_button 'Issue actions'

    expect(page).to have_link('New issue', href: new_project_issue_path(project))
    expect(page).to have_button('Create merge request')
    expect(page).to have_button('Close issue')
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
        let(:user_with_status) { user }
      end
    end

    context 'when showing status of a user who commented on an issue', :js do
      it_behaves_like 'showing user status' do
        let(:user_with_status) { user }
      end
    end

    context 'when status message has an emoji', :js do
      let_it_be(:message) { 'My status with an emoji' }
      let_it_be(:message_emoji) { 'basketball' }
      let_it_be(:status) { create(:user_status, user: user, emoji: 'smirk', message: "#{message} :#{message_emoji}:") }

      it 'correctly renders the emoji' do
        wait_for_requests

        tooltip_span = page.first(".user-status-emoji[title^='#{message}']")

        tooltip_span.hover

        wait_for_requests

        tooltip = page.find('.tooltip .tooltip-inner')

        page.within(tooltip) do
          expect(page).to have_emoji(message_emoji)
        end
      end
    end
  end
end
