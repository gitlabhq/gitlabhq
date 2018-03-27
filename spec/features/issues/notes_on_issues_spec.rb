require 'spec_helper'

describe 'Create notes on issues', :js do
  let(:user) { create(:user) }

  shared_examples 'notes with reference' do
    let(:issue) { create(:issue, project: project) }
    let(:note_text) { "Check #{mention.to_reference}" }

    before do
      project.add_developer(user)
      sign_in(user)
      visit project_issue_path(project, issue)

      fill_in 'note[note]', with: note_text
      click_button 'Comment'

      wait_for_requests
    end

    it 'creates a note with reference and cross references the issue' do
      page.within('div#notes li.note div.note-text') do
        expect(page).to have_content(note_text)
        expect(page.find('a')).to have_content(mention.to_reference)
      end

      find('div#notes li.note div.note-text a').click

      page.within('div#notes li.note .system-note-message') do
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
end
