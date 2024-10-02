# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Snippets tab on a user profile', :js, feature_category: :source_code_management do
  context 'when the user has snippets' do
    let(:user) { create(:user) }

    before do
      stub_feature_flags(profile_tabs_vue: false)
    end

    context 'pagination' do
      let!(:snippets) { create_list(:personal_snippet, 2, :public, author: user) }

      before do
        allow(Snippet).to receive(:default_per_page).and_return(1)
        visit user_path(user)
        within_testid('super-sidebar') { click_link 'Snippets' }
        wait_for_requests
      end

      it_behaves_like 'paginated snippets', remote: true
    end

    context 'list content' do
      let!(:public_snippet) { create(:personal_snippet, :public, author: user) }
      let!(:internal_snippet) { create(:personal_snippet, :internal, author: user) }
      let!(:private_snippet) { create(:personal_snippet, :private, author: user) }
      let!(:other_snippet) { create(:personal_snippet, :public) }

      it 'contains only internal and public snippets of a user when a user is logged in' do
        sign_in(create(:user))
        visit user_path(user)
        within_testid('super-sidebar') { click_link 'Snippets' }
        wait_for_requests

        expect(page).to have_css('[data-testid="snippet-link"]', count: 2)

        expect(page).to have_content(public_snippet.title)
        expect(page).to have_content(internal_snippet.title)
      end

      it 'contains only public snippets of a user when a user is not logged in' do
        visit user_path(user)
        within_testid('super-sidebar') { click_link 'Snippets' }
        wait_for_requests

        expect(page).to have_css('[data-testid="snippet-link"]', count: 1)
        expect(page).to have_content(public_snippet.title)
      end
    end
  end
end
