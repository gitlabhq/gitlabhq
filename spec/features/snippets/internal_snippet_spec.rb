# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Internal Snippets', :js, feature_category: :source_code_management do
  let(:internal_snippet) { create(:personal_snippet, :internal, :repository) }
  let(:content) { internal_snippet.blobs.first.data.strip! }

  describe 'normal user' do
    before do
      sign_in(create(:user))
    end

    it 'sees internal snippets' do
      visit snippet_path(internal_snippet)

      expect(page).to have_content(content)
    end

    it 'sees raw internal snippets' do
      visit raw_snippet_path(internal_snippet)

      expect(page).to have_content(content)
    end
  end
end
