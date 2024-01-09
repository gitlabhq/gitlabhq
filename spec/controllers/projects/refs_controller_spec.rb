# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RefsController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_developer(user)
  end

  describe 'GET #switch' do
    context 'with normal parameters' do
      using RSpec::Parameterized::TableSyntax

      let(:id) { 'master' }
      let(:id_and_path) { "#{id}/#{path}" }

      let(:params) do
        { destination: destination, namespace_id: project.namespace.to_param, project_id: project, id: id,
          ref_type: ref_type, path: path }
      end

      subject { get :switch, params: params }

      where(:destination, :ref_type, :path, :redirected_to) do
        'tree'           | nil     | nil       | lazy { project_tree_path(project, id) }
        'tree'           | 'heads' | nil       | lazy { project_tree_path(project, id) }
        'tree'           | nil     | 'foo/bar' | lazy { project_tree_path(project, id_and_path) }
        'blob'           | nil     | nil       | lazy { project_blob_path(project, id) }
        'blob'           | 'heads' | nil       | lazy { project_blob_path(project, id) }
        'blob'           | nil     | 'foo/bar' | lazy { project_blob_path(project, id_and_path) }
        'graph'          | nil     | nil       | lazy { project_network_path(project, id) }
        'graph'          | 'heads' | nil       | lazy { project_network_path(project, id, ref_type: 'heads') }
        'graph'          | nil     | 'foo/bar' | lazy { project_network_path(project, id_and_path) }
        'graphs'         | nil     | nil       | lazy { project_graph_path(project, id) }
        'graphs'         | 'heads' | nil       | lazy { project_graph_path(project, id, ref_type: 'heads') }
        'graphs'         | nil     | 'foo/bar' | lazy { project_graph_path(project, id_and_path) }
        'find_file'      | nil     | nil       | lazy { project_find_file_path(project, id) }
        'find_file'      | 'heads' | nil       | lazy { project_find_file_path(project, id) }
        'find_file'      | nil     | 'foo/bar' | lazy { project_find_file_path(project, id_and_path) }
        'graphs_commits' | nil     | nil       | lazy { commits_project_graph_path(project, id) }
        'graphs_commits' | 'heads' | nil       | lazy { commits_project_graph_path(project, id) }
        'graphs_commits' | nil     | 'foo/bar' | lazy { commits_project_graph_path(project, id_and_path) }
        'badges'         | nil     | nil       | lazy { project_settings_ci_cd_path(project, ref: id) }
        'badges'         | 'heads' | nil       | lazy { project_settings_ci_cd_path(project, ref: id) }
        'badges'         | nil     | 'foo/bar' | lazy { project_settings_ci_cd_path(project, ref: id_and_path) }
        'commits'        | nil     | nil       | lazy { project_commits_path(project, id) }
        'commits'        | 'heads' | nil       | lazy { project_commits_path(project, id, ref_type: 'heads') }
        'commits'        | nil     | 'foo/bar' | lazy { project_commits_path(project, id_and_path) }
        nil              | nil     | nil       | lazy { project_commits_path(project, id) }
        nil              | 'heads' | nil       | lazy { project_commits_path(project, id, ref_type: 'heads') }
        nil              | nil     | 'foo/bar' | lazy { project_commits_path(project, id_and_path) }
      end

      with_them do
        it 'redirects to destination' do
          expect(subject).to redirect_to(redirected_to)
        end
      end
    end

    context 'with bad path parameter' do
      it 'returns 400 bad request' do
        params = {
          destination: 'tree',
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: 'master',
          ref_type: nil,
          path: '../bad_path_redirect'
        }

        get :switch, params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with an invalid path parameter' do
      it 'returns 400 bad request' do
        params = {
          destination: 'graphs_commits',
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: 'master',
          ref_type: nil,
          path: '*'
        }

        get :switch, params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'GET #logs_tree' do
    let(:path) { 'foo/bar/baz.html' }

    def default_get(format = :html)
      get :logs_tree, params: {
        namespace_id: project.namespace.to_param, project_id: project, id: 'master', path: path
      }, format: format
    end

    def xhr_get(format = :html, params = {})
      get :logs_tree, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: 'master',
        path: path,
        format: format
      }.merge(params), xhr: true
    end

    it 'never throws MissingTemplate' do
      expect { default_get }.not_to raise_error
      expect { xhr_get(:json) }.not_to raise_error
      expect { xhr_get }.not_to raise_error
    end

    it 'renders 404 for HTML requests' do
      xhr_get

      expect(response).to be_not_found
    end

    context 'when ref is incorrect' do
      it 'returns 404 page' do
        xhr_get(:json, id: '.')

        expect(response).to be_not_found
      end
    end

    context 'when offset has an invalid format' do
      it 'renders JSON' do
        xhr_get(:json, offset: { wrong: :format })

        expect(response).to be_successful
        expect(json_response).to be_kind_of(Array)
      end
    end

    context 'when json is requested' do
      it 'renders JSON' do
        expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

        xhr_get(:json)

        expect(response).to be_successful
        expect(json_response).to be_kind_of(Array)
      end
    end
  end
end
