require 'spec_helper'

describe 'User searches for comments' do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_reporter(user)
    sign_in(user)

    visit(project_path(project))
  end

  context 'when a comment is in commits' do
    context 'when comment belongs to an invalid commit' do
      let(:comment) { create(:note_on_commit, author: user, project: project, commit_id: 12345678, note: 'Bug here') }

      it 'finds a commit' do
        page.within('.search') do
          fill_in('search', with: comment.note)
          click_button('Go')
        end

        click_link('Comments')

        expect(page).to have_text('Commit deleted')
        expect(page).to have_text('12345678')
      end
    end
  end

  context 'when a comment is in a snippet' do
    let(:snippet) { create(:project_snippet, :private, project: project, author: user, title: 'Some title') }
    let(:comment) { create(:note, noteable: snippet, author: user, note: 'Supercalifragilisticexpialidocious', project: project) }

    it 'finds a snippet' do
      page.within('.search') do
        fill_in('search', with: comment.note)
        click_button('Go')
      end

      click_link('Comments')

      expect(page).to have_link(snippet.title)
    end
  end
end
