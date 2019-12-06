# frozen_string_literal: true

require 'spec_helper'

describe 'Snippets' do
  context 'when the project has snippets' do
    let(:project) { create(:project, :public) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.owner, project: project) }

    before do
      allow(Snippet).to receive(:default_per_page).and_return(1)

      visit project_snippets_path(project)
    end

    it_behaves_like 'paginated snippets'
  end

  describe 'rendering engine' do
    let_it_be(:snippet) { create(:personal_snippet, :public) }
    let(:snippets_vue_feature_flag_enabled) { true }

    before do
      stub_feature_flags(snippets_vue: snippets_vue_feature_flag_enabled)

      visit snippet_path(snippet)
    end

    it 'renders Vue application' do
      expect(page).to have_selector('#js-snippet-view')
      expect(page).not_to have_selector('.personal-snippets')
    end

    context 'when feature flag is disabled' do
      let(:snippets_vue_feature_flag_enabled) { false }

      it 'renders HAML application and not Vue' do
        expect(page).not_to have_selector('#js-snippet-view')
        expect(page).to have_selector('.personal-snippets')
      end
    end
  end
end
