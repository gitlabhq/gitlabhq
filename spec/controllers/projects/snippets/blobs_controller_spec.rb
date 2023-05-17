# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Snippets::BlobsController do
  using RSpec::Parameterized::TableSyntax
  include SnippetHelpers

  let_it_be(:author)       { create(:user) }
  let_it_be(:developer)    { create(:user) }
  let_it_be(:other_user)   { create(:user) }

  let(:visibility)         { :public }
  let(:project_visibility) { :public }
  let(:project)            { create(:project, project_visibility) }
  let(:snippet)            { create(:project_snippet, visibility, :repository, project: project, author: author) }

  before do
    project.add_maintainer(author)
    project.add_developer(developer)
  end

  describe 'GET #raw' do
    let(:filepath) { 'file1' }
    let(:ref) { TestEnv::BRANCH_SHA['snippet/single-file'] }
    let(:inline) { nil }

    subject do
      get :raw, params: {
        namespace_id: project.namespace,
        project_id: project,
        snippet_id: snippet,
        path: filepath,
        ref: ref,
        inline: inline
      }
    end

    context 'with a snippet without a repository' do
      let(:snippet) { create(:project_snippet, visibility, project: project, author: author) }

      it_behaves_like 'raw snippet without repository', :not_found
    end

    where(:project_visibility_level, :snippet_visibility_level, :user, :status) do
      :public  | :public  | :author     | :ok
      :public  | :public  | :developer  | :ok
      :public  | :public  | :other_user | :ok
      :public  | :public  | nil         | :ok

      :public  | :private | :author     | :ok
      :public  | :private | :developer  | :ok
      :public  | :private | :other_user | :not_found
      :public  | :private | nil         | :not_found

      :private | :public  | :author     | :ok
      :private | :public  | :developer  | :ok
      :private | :public  | :other_user | :not_found
      :private | :public  | nil         | :redirect

      :private | :private | :author     | :ok
      :private | :private | :developer  | :ok
      :private | :private | :other_user | :not_found
      :private | :private | nil         | :redirect
    end

    with_them do
      let(:visibility) { snippet_visibility_level }
      let(:project_visibility) { project_visibility_level }

      before do
        sign_in_as(user)

        subject
      end

      it 'responds with correct status' do
        expect(response).to have_gitlab_http_status(status)
      end
    end

    it_behaves_like 'raw snippet blob'
  end
end
