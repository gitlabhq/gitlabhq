# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create notes on issues', :js, feature_category: :team_planning do
  let(:user) { create(:user) }

  def submit_comment(text)
    fill_in 'note[note]', with: text
    click_button 'Comment'
    wait_for_requests
  end

  shared_examples 'notes with reference' do
    let(:issue) { create(:issue, project: project) }
    let(:note_text) { "Check #{mention.to_reference}" }

    before do
      project.add_developer(user)
      sign_in(user)
      visit project_issue_path(project, issue)

      submit_comment(note_text)
    end

    it 'creates a note with reference and cross references the issue', :sidekiq_might_not_need_inline do
      page.within('div#notes li.note div.note-text') do
        expect(page).to have_content(note_text)
        expect(page.find('a')).to have_content(mention.to_reference)
      end

      find('div#notes li.note div.note-text a').click

      page.within('div#notes li.system-note .system-note-message') do
        expect(page).to have_content('mentioned in issue')
        expect(page.find('a')).to have_content(issue.to_reference)
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
    submit_comment("@#{user.username} note to self")

    expect(page).to have_selector '.gfm-project_member.current-user', text: user.username
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

        page.within('div#notes li.system-note .system-note-message') do
          expect(page).to have_content('closed with')
          expect(page.find('a')).to have_content(reference_content)
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
