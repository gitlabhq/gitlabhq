# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Snippets > User views snippets', feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }

  let(:user) { create(:user) }

  def visit_project_snippets
    visit(project_snippets_path(project))
  end

  context 'snippets list' do
    let!(:project_snippet) { create(:project_snippet, project: project, author: user) }
    let!(:snippet) { create(:project_snippet, author: user) }
    let(:snippets) { [project_snippet, snippet] } # Used by the shared examples

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    context 'pagination' do
      before do
        create(:project_snippet, project: project, author: user)
        allow(Snippet).to receive(:default_per_page).and_return(1)

        visit_project_snippets
      end

      it_behaves_like 'paginated snippets'
    end

    context 'filtering by visibility' do
      before do
        visit_project_snippets
      end

      it_behaves_like 'tabs with counts' do
        let_it_be(:counts) { { all: '1', public: '0', private: '1', internal: '0' } }
      end
    end

    it 'shows snippets' do
      visit_project_snippets

      expect(page).to have_link(project_snippet.title, href: project_snippet_path(project, project_snippet))
      expect(page).not_to have_content(snippet.title)
    end
  end

  context 'when current user is a guest' do
    before do
      project.add_guest(user)
      sign_in(user)
    end

    context 'when snippets list is empty' do
      it 'hides New Snippet button' do
        visit_project_snippets

        page.within(find('.gl-empty-state')) do
          expect(page).not_to have_link('New snippet')
        end
      end
    end

    context 'when project has snippets' do
      let!(:project_snippet) { create(:project_snippet, project: project, author: user) }

      it 'hides New Snippet button' do
        visit_project_snippets

        page.within(find('.top-area')) do
          expect(page).not_to have_link('New snippet')
        end
      end
    end
  end

  context 'when current user is not a guest' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    context 'when snippets list is empty' do
      it 'shows New Snippet button' do
        visit_project_snippets

        page.within(find('.gl-empty-state')) do
          expect(page).to have_link('New snippet')
        end
      end
    end

    context 'when project has snippets' do
      let!(:project_snippet) { create(:project_snippet, project: project, author: user) }

      it 'shows New Snippet button' do
        visit_project_snippets

        page.within(find('.top-area')) do
          expect(page).to have_link('New snippet')
        end
      end
    end
  end
end
