# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::BlobsController do
  using RSpec::Parameterized::TableSyntax
  include SnippetHelpers

  describe 'GET #raw' do
    let_it_be(:author)     { create(:user) }
    let_it_be(:other_user) { create(:user) }

    let(:visibility)       { :public }
    let(:snippet)          { create(:personal_snippet, visibility, :repository, author: author) }
    let(:filepath)         { 'file1' }
    let(:ref)              { TestEnv::BRANCH_SHA['snippet/single-file'] }
    let(:inline)           { nil }

    subject do
      get :raw, params: { snippet_id: snippet, path: filepath, ref: ref, inline: inline }
    end

    where(:snippet_visibility_level, :user, :status) do
      :public  | :author     | :ok
      :public  | :other_user | :ok
      :public  | nil         | :ok

      :private | :author     | :ok
      :private | :other_user | :not_found
      :private | nil         | :redirect
    end

    with_them do
      let(:visibility) { snippet_visibility_level }

      before do
        sign_in_as(user)

        subject
      end

      it 'responds with correct status' do
        expect(response).to have_gitlab_http_status(status)
      end
    end

    it_behaves_like 'raw snippet blob'

    context 'with a snippet without a repository' do
      let(:snippet) { create(:personal_snippet, visibility, author: author) }

      it_behaves_like 'raw snippet without repository', :redirect
    end
  end
end
