# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create notes on issues', :js, feature_category: :team_planning do
  let(:user) { create(:user) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  shared_examples 'notes with reference' do
    let(:issue) { create(:issue, project: project) }
    let(:note_text) { "Check #{mention.to_reference}" }

    before do
      project.add_developer(user)
      sign_in(user)
      visit project_issue_path(project, issue)

      fill_in 'Add a reply', with: note_text
      click_button 'Comment'
    end

    it 'creates a note with reference and cross references the issue', :sidekiq_might_not_need_inline do
      page.within('.note') do
        expect(page).to have_text(note_text)
        expect(page).to have_link(mention.to_reference)
      end

      click_link(mention.to_reference)

      page.within('.system-note') do
        expect(page).to have_text('mentioned in issue')
        expect(page).to have_link(issue.to_reference)
      end
    end
  end

  context 'mentioning issue on a private project' do
    it_behaves_like 'notes with reference' do
      let(:project) { create(:project, :private) }
      let(:mention) { create(:issue, project: project) }
    end
  end

  context 'mentioning issue on an internal project' do
    it_behaves_like 'notes with reference' do
      let(:project) { create(:project, :internal) }
      let(:mention) { create(:issue, project: project) }
    end
  end

  context 'mentioning issue on a public project' do
    it_behaves_like 'notes with reference' do
      let(:project) { create(:project, :public) }
      let(:mention) { create(:issue, project: project) }
    end
  end

  context 'mentioning merge request on a private project' do
    it_behaves_like 'notes with reference' do
      let(:project) { create(:project, :private, :repository) }
      let(:mention) { create(:merge_request, source_project: project) }
    end
  end

  context 'mentioning merge request on an internal project' do
    it_behaves_like 'notes with reference' do
      let(:project) { create(:project, :internal, :repository) }
      let(:mention) { create(:merge_request, source_project: project) }
    end
  end

  context 'mentioning merge request on a public project' do
    it_behaves_like 'notes with reference' do
      let(:project) { create(:project, :public, :repository) }
      let(:mention) { create(:merge_request, source_project: project) }
    end
  end

  it 'highlights the current user in a comment' do
    project = create(:project)
    issue = create(:issue, project: project)
    project.add_developer(user)
    sign_in(user)
    visit project_issue_path(project, issue)

    fill_in 'Add a reply', with: "@#{user.username} note to self"
    click_button 'Comment'

    within('.note') do
      expect(page).to have_link "@#{user.username}"
    end
  end

  shared_examples "when reference belongs to a private project" do
    let(:project) { create(:project, :private, :repository) }
    let(:issue) { create(:issue, project: project) }

    before do
      sign_in(user)
    end

    context 'when the user does not have permission to see the reference' do
      before do
        project.add_guest(user)
      end

      it 'does not show the user the reference' do
        visit project_issue_path(project, issue)

        expect(page).not_to have_content('closed with')
      end
    end

    context 'when the user has permission to see the reference' do
      before do
        project.add_developer(user)
      end

      it 'shows the user the reference' do
        visit project_issue_path(project, issue)

        page.within('.system-note') do
          expect(page).to have_text('closed with')
          expect(page).to have_link(reference_content)
        end
      end
    end
  end

  context 'when the issue is closed via a merge request' do
    it_behaves_like "when reference belongs to a private project" do
      let(:reference) { create(:merge_request, source_project: project) }
      let(:reference_content) { reference.to_reference }

      before do
        create(:resource_state_event, issue: issue, state: :closed, created_at: '2020-02-05', source_merge_request: reference)
      end
    end
  end

  context 'when the issue is closed via a commit' do
    it_behaves_like "when reference belongs to a private project" do
      let(:reference) { create(:commit, project: project) }
      let(:reference_content) { reference.short_sha }

      before do
        create(:resource_state_event, issue: issue, state: :closed, created_at: '2020-02-05', source_commit: reference.id)
      end
    end
  end
end
