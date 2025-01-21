# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Ci::LintsController, feature_category: :pipeline_composition do
  include StubRequests

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    context 'with enough privileges' do
      before do
        project.add_developer(user)

        get :show, params: { namespace_id: project.namespace, project_id: project }
      end

      it { expect(response).to have_gitlab_http_status(:ok) }

      it 'renders show page' do
        expect(response).to render_template :show
      end

      it 'retrieves project' do
        expect(assigns(:project)).to eq(project)
      end
    end

    context 'without enough privileges' do
      before do
        project.add_guest(user)

        get :show, params: { namespace_id: project.namespace, project_id: project }
      end

      it 'responds with 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: params }

    let(:params) { { namespace_id: project.namespace, project_id: project, content: content, format: :json } }
    let(:remote_file_path) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
    let(:parsed_body) { Gitlab::Json.parse(response.body) }

    let(:remote_file_content) do
      <<~HEREDOC
      before_script:
        - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
        - ruby -v
        - which ruby
        - bundle install --jobs $(nproc)  "${FLAGS[@]}"
      HEREDOC
    end

    let(:content) do
      <<~HEREDOC
      include:
        - #{remote_file_path}

      rubocop:
        script:
          - bundle exec rubocop
      HEREDOC
    end

    shared_examples 'returns a successful validation' do
      before do
        subject
      end

      it 'returns successfully' do
        expect(response).to have_gitlab_http_status :ok
      end

      it 'renders json' do
        expect(response.media_type).to eq 'application/json'
        expect(parsed_body).to include('errors', 'warnings', 'jobs', 'valid')
        expect(parsed_body).to match_schema('entities/lint_result_entity')
      end

      it 'retrieves project' do
        expect(assigns(:project)).to eq(project)
      end
    end

    context 'with a valid gitlab-ci.yml' do
      before do
        stub_full_request(remote_file_path).to_return(body: remote_file_content)
        project.add_developer(user)
      end

      it_behaves_like 'returns a successful validation'

      context 'using legacy validation (YamlProcessor)' do
        it_behaves_like 'returns a successful validation'

        it 'runs validations through YamlProcessor' do
          expect(Gitlab::Ci::YamlProcessor).to receive(:new).and_call_original

          subject
        end
      end

      context 'using dry_run mode' do
        subject { post :create, params: params.merge(dry_run: 'true') }

        it_behaves_like 'returns a successful validation'

        it 'runs validations through Ci::CreatePipelineService' do
          expect(Ci::CreatePipelineService)
            .to receive(:new)
            .with(project, user, ref: 'master')
            .and_call_original

          subject
        end
      end
    end

    context 'with an invalid gitlab-ci.yml' do
      let(:content) do
        <<~HEREDOC
        rubocop:
          scriptt:
            - bundle exec rubocop
        HEREDOC
      end

      before do
        project.add_developer(user)
        subject
      end

      it_behaves_like 'returns a successful validation'

      it 'assigns result with errors' do
        expect(parsed_body['errors']).to match_array(
          [
            'jobs rubocop config should implement the script:, run:, or trigger: keyword',
            'jobs config should contain at least one visible job'
          ])
      end

      context 'with dry_run mode' do
        subject { post :create, params: params.merge(dry_run: 'true') }

        it 'assigns result with errors' do
          expect(
            parsed_body['errors']
          ).to match_array(['jobs rubocop config should implement the script:, run:, or trigger: keyword'])
        end

        it_behaves_like 'returns a successful validation'
      end
    end

    context 'when the current user cannot run pipelines at all' do
      before do
        project.add_guest(user)
      end

      it 'responds with a 404' do
        post :create, params: { namespace_id: project.namespace, project_id: project, content: content }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the current user cannot run pipelines on protected branches' do
      # The create action lints the given CI config as if it was on the default branch.
      # The default branch is protected by default, which means it can access protected variables.
      # Developers don't have permission to access protected variables,
      # so we can't allow them to use this endpoint.

      let(:content) do
        <<~HEREDOC
        include:
          - #{remote_file_path}

        rubocop:
          script:
            - bundle exec rubocop
        HEREDOC
      end

      let(:remote_file_path) { 'https://test.example.com/${SECRET_TOKEN}.yml' }

      before do
        project.add_developer(user)

        sha = project.repository.commit.sha # this is always the sha used by this endpoint for linting
        ref = Gitlab::Ci::RefFinder.new(project).find_by_sha(sha)

        create(:protected_branch, name: ref, project: project)
        create(:ci_variable, key: 'SECRET_TOKEN', value: 'secret!!!!!', project: project, protected: true)
      end

      it 'does not expand protected variables' do
        post :create, params: { namespace_id: project.namespace, project_id: project, content: content }

        expect(parsed_body['errors']).to match_array([
          'Included file `https://test.example.com/.yml` does not have YAML extension!'
        ])
      end
    end
  end
end
