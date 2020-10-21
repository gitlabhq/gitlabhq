# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User deletes snippet', :js do
  let(:user) { create(:user) }
  let(:content) { 'puts "test"' }
  let(:snippet) { create(:personal_snippet, :repository, :public, content: content, author: user) }

  before do
    sign_in(user)

    visit snippet_path(snippet)
  end

  it 'deletes the snippet' do
    expect(page).to have_content(snippet.title)

    click_button('Delete')
    click_button('Delete snippet')
    wait_for_requests

    expect(page).not_to have_content(snippet.title)
  end
end
