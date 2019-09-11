# frozen_string_literal: true

require 'spec_helper'

describe Explore::SnippetsController do
  describe 'GET #index' do
    it_behaves_like 'paginated collection' do
      let(:collection) { Snippet.all }

      before do
        create(:personal_snippet, :public)
      end
    end
  end
end
