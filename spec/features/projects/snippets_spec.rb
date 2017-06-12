require 'spec_helper'

describe 'Project snippets', :js, feature: true do
  context 'when the project has snippets' do
    let(:project) { create(:empty_project, :public) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.owner, project: project) }
    let!(:other_snippet) { create(:project_snippet) }

    context 'pagination' do
      before do
        allow(Snippet).to receive(:default_per_page).and_return(1)

        visit namespace_project_snippets_path(project.namespace, project)
      end

      it_behaves_like 'paginated snippets'
    end

    context 'list content' do
      it 'contains all project snippets' do
        visit namespace_project_snippets_path(project.namespace, project)

        expect(page).to have_selector('.snippet-row', count: 2)

        expect(page).to have_content(snippets[0].title)
        expect(page).to have_content(snippets[1].title)
      end
    end

    context 'when submitting a note' do
      before do
        login_as :admin
        visit namespace_project_snippet_path(project.namespace, project, snippets[0])
      end

      it 'should not have autocomplete' do
        wait_for_requests
        request_count_before = page.driver.network_traffic.count

        find('#note_note').native.send_keys('')
        fill_in 'note[note]', with: '@'

        wait_for_requests
        request_count_after = page.driver.network_traffic.count

        # This selector probably won't be in place even if autocomplete was enabled
        # but we want to make sure
        expect(page).not_to have_selector('.atwho-view')
        expect(request_count_before).to eq(request_count_after)
      end
    end
  end
end
