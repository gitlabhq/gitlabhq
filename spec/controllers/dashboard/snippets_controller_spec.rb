# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::SnippetsController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    it_behaves_like 'paginated collection' do
      let(:collection) { Snippet.all }

      before do
        create(:personal_snippet, :public, author: user)
      end
    end
  end
end
