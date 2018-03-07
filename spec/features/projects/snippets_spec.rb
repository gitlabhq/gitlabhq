require 'spec_helper'

describe 'Project snippets', :js do
  context 'when the project has snippets' do
    let(:project) { create(:project, :public) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.owner, project: project) }
    let!(:other_snippet) { create(:project_snippet) }

    context 'pagination' do
      before do
        allow(Snippet).to receive(:default_per_page).and_return(1)

        visit project_snippets_path(project)
      end

      it_behaves_like 'paginated snippets'
    end

    context 'list content' do
      it 'contains all project snippets' do
        visit project_snippets_path(project)

        expect(page).to have_selector('.snippet-row', count: 2)

        expect(page).to have_content(snippets[0].title)
        expect(page).to have_content(snippets[1].title)
      end
    end

    context 'when submitting a note' do
      before do
        sign_in(create(:admin))
        visit project_snippet_path(project, snippets[0])
      end

      it 'should have autocomplete' do
        find('#note_note').native.send_keys('')
        fill_in 'note[note]', with: '@'

        expect(page).to have_selector('.atwho-view')
      end

      it 'should have zen mode' do
        find('.js-zen-enter').click()
        expect(page).to have_selector('.fullscreen')
      end
    end
  end
end
