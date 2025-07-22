# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'viewing an issue', :js, feature_category: :service_desk do
  let_it_be(:user) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_refind(:issue) { create(:issue, project: project) }
  let_it_be(:note) { create(:note_on_issue, project: project, noteable: issue) }
  let_it_be(:participants) { create_list(:issue_email_participant, 4, issue: issue) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    project.add_reporter(user)
  end

  shared_examples 'email participants warning in all editors' do
    context 'for a new note' do
      it 'shows the correct message' do
        expect(page).to have_content(", and 1 more will be notified of your comment")
      end
    end

    context 'for a reply form' do
      before do
        click_button 'Reply to comment'
      end

      it 'shows the correct message' do
        expect(page).to have_content(", and 1 more will be notified of your comment")
      end
    end
  end

  context 'when issue is confidential' do
    let!(:confidential_issue) { create(:issue, project: project, confidential: true) }
    let!(:confidential_note) { create(:note_on_issue, project: project, noteable: confidential_issue) }
    let!(:confidential_participants) { create_list(:issue_email_participant, 4, issue: confidential_issue) }

    before do
      sign_in(user)
      visit project_issue_path(project, confidential_issue)
    end

    it_behaves_like 'email participants warning in all editors'
  end

  context 'when issue is not confidential' do
    context 'with signed in user' do
      context 'when user has no role in project' do
        before do
          sign_in(non_member)
          visit project_issue_path(project, issue)
        end

        it_behaves_like 'email participants warning in all editors'
      end

      context 'when user has (at least) reporter role in project' do
        before do
          sign_in(user)
          visit project_issue_path(project, issue)
        end

        it_behaves_like 'email participants warning in all editors'
      end
    end
  end
end
