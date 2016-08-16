require 'spec_helper'

feature 'Member autocomplete', feature: true do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }
  let(:participant) { create(:user) }
  let(:author) { create(:user) }

  before do
    allow_any_instance_of(Commit).to receive(:author).and_return(author)
    login_as user
  end

  shared_examples "open suggestions" do
    it 'displays suggestions' do
      expect(page).to have_selector('.atwho-view', visible: true)
    end

    it 'suggests author' do
      page.within('.atwho-view', visible: true) do
        expect(page).to have_content(author.username)
      end
    end

    it 'suggests participant' do
      page.within('.atwho-view', visible: true) do
        expect(page).to have_content(participant.username)
      end
    end
  end

  context 'adding a new note on a Issue', js: true do
    before do
      issue = create(:issue, author: author, project: project)
      create(:note, note: 'Ultralight Beam', noteable: issue,
                    project: project, author: participant)
      visit_issue(project, issue)
    end

    context 'when typing @' do
      include_examples "open suggestions"
      before do
        open_member_suggestions
      end
    end
  end

  context 'adding a new note on a Merge Request ', js: true do
    before do
      merge = create(:merge_request, source_project: project, target_project: project, author: author)
      create(:note, note: 'Ultralight Beam', noteable: merge,
                    project: project, author: participant)
      visit_merge_request(project, merge)
    end

    context 'when typing @' do
      include_examples "open suggestions"
      before do
        open_member_suggestions
      end
    end
  end

  context 'adding a new note on a Commit ', js: true do
    let(:commit)  { project.commit }

    before do
      allow(commit).to receive(:author).and_return(author)
      create(:note_on_commit, author: participant, project: project, commit_id: project.repository.commit.id, note: 'No More Parties in LA')
      visit_commit(project, commit)
    end

    context 'when typing @' do
      include_examples "open suggestions"
      before do
        open_member_suggestions
      end
    end
  end

  def open_member_suggestions
    sleep 1
    page.within('.new-note') do
      sleep 1
      find('#note_note').native.send_keys('@')
    end
  end

  def visit_issue(project, issue)
    visit namespace_project_issue_path(project.namespace, project, issue)
  end

  def visit_merge_request(project, merge)
    visit namespace_project_merge_request_path(project.namespace, project, merge)
  end

  def visit_commit(project, commit)
    visit namespace_project_commit_path(project.namespace, project, commit)
  end
end
