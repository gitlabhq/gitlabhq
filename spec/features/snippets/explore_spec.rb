# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Explore Snippets', feature_category: :source_code_management do
  let!(:public_snippet) { create(:personal_snippet, :public) }
  let!(:internal_snippet) { create(:personal_snippet, :internal) }
  let!(:private_snippet) { create(:personal_snippet, :private) }

  context 'User' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
      visit explore_snippets_path
    end

    it 'see snippets that are not private' do
      expect(page).to have_content(public_snippet.title)
      expect(page).to have_content(internal_snippet.title)
      expect(page).not_to have_content(private_snippet.title)
    end

    it 'shows new snippet button in header' do
      parent_element = page.find('.page-title-controls')
      expect(parent_element).to have_link('New snippet')
    end
  end

  context 'External user' do
    let(:user) { create(:user, :external) }

    before do
      sign_in(user)
      visit explore_snippets_path
    end

    it 'see only public snippets' do
      expect(page).to have_content(public_snippet.title)
      expect(page).not_to have_content(internal_snippet.title)
      expect(page).not_to have_content(private_snippet.title)
    end

    context 'without snippets' do
      before do
        Snippet.delete_all
      end

      it 'hides new snippet button' do
        expect(page).not_to have_link('New snippet')
      end
    end

    context 'with snippets' do
      it 'hides new snippet button' do
        expect(page).not_to have_link('New snippet')
      end
    end
  end

  context 'Not authenticated user' do
    before do
      visit explore_snippets_path
    end

    it 'see only public snippets' do
      expect(page).to have_content(public_snippet.title)
      expect(page).not_to have_content(internal_snippet.title)
      expect(page).not_to have_content(private_snippet.title)
    end
  end
end
