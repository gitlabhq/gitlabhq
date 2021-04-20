# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::SnippetsController do
  describe 'GET #index' do
    let!(:project_snippet) { create_list(:project_snippet, 3, :public) }
    let!(:personal_snippet) { create_list(:personal_snippet, 3, :public) }

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(2)
    end

    it 'renders' do
      get :index

      snippets = assigns(:snippets)

      expect(snippets).to be_a(::Kaminari::PaginatableWithoutCount)
      expect(snippets.size).to eq(2)
      expect(snippets).to all(be_a(PersonalSnippet))
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'renders pagination' do
      get :index, params: { page: 2 }

      snippets = assigns(:snippets)

      expect(snippets).to be_a(::Kaminari::PaginatableWithoutCount)
      expect(snippets.size).to eq(1)
      expect(assigns(:snippets)).to all(be_a(PersonalSnippet))
      expect(response).to have_gitlab_http_status(:ok)
    end

    it_behaves_like 'snippets views' do
      let_it_be(:user) { create(:user) }
    end
  end
end
