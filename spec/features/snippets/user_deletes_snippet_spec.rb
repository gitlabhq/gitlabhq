# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User deletes snippet', :js, feature_category: :source_code_management do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:content) { 'puts "test"' }
  let(:snippet) { create(:personal_snippet, :repository, :public, content: content, author: user) }

  before do
    sign_in(user)

    visit snippet_path(snippet)
  end

  it 'deletes the snippet' do
    expect(page).to have_content(snippet.title)

    click_on 'Snippet actions'

    page.within(find_by_testid('snippets-more-actions-dropdown')) do
      click_on 'Delete'
    end

    within_modal do
      click_button 'Delete snippet'
    end

    wait_for_requests

    expect(page).to have_link('New snippet')
    expect(page).not_to have_content(snippet.title)
  end
end
