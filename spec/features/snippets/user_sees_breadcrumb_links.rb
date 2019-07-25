# frozen_string_literal: true

require 'rails_helper'

describe 'New user snippet breadcrumbs' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit new_snippet_path
  end

  it 'display a link to user snippets and new user snippet pages' do
    page.within '.breadcrumbs' do
      expect(find_link('Snippets')[:href]).to end_with(dashboard_snippets_path)
      expect(find_link('New')[:href]).to end_with(new_snippet_path)
    end
  end
end
