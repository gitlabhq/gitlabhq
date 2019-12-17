# frozen_string_literal: true

require 'spec_helper'

describe 'Explore Snippets' do
  let!(:public_snippet) { create(:personal_snippet, :public) }
  let!(:internal_snippet) { create(:personal_snippet, :internal) }
  let!(:private_snippet) { create(:personal_snippet, :private) }
  let(:user) { nil }

  before do
    sign_in(user) if user
    visit explore_snippets_path
  end

  context 'User' do
    let(:user) { create(:user) }

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
    it 'see only public snippets' do
      expect(page).to have_content(public_snippet.title)
      expect(page).not_to have_content(internal_snippet.title)
      expect(page).not_to have_content(private_snippet.title)
    end
  end
end
