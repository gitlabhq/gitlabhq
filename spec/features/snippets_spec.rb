# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Snippets', feature_category: :source_code_management do
  context 'when the project has snippets' do
    let(:project) { create(:project, :public) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.first_owner, project: project) }

    before do
      allow(Snippet).to receive(:default_per_page).and_return(1)

      visit project_snippets_path(project)
    end

    it_behaves_like 'paginated snippets'
  end

  describe 'rendering engine' do
    let_it_be(:snippet) { create(:personal_snippet, :public) }

    before do
      visit snippet_path(snippet)
    end

    it 'renders Vue application' do
      expect(page).to have_selector('#js-snippet-view')
      expect(page).not_to have_selector('.personal-snippets')
    end
  end
end
