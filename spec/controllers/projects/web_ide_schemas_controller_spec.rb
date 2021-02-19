# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::WebIdeSchemasController do
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :private, :repository, namespace: developer.namespace) }

  before do
    project.add_developer(developer)

    sign_in(user)
  end

  describe 'GET show' do
    let(:user) { developer }
    let(:branch) { 'master' }

    subject do
      get :show, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        branch: branch,
        filename: 'package.json'
      }
    end

    before do
      allow_next_instance_of(::Ide::SchemasConfigService) do |instance|
        allow(instance).to receive(:execute).and_return(result)
      end
    end

    context 'when branch is invalid' do
      let(:branch) { 'non-existent' }

      it 'returns 422' do
        subject

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when a valid schema exists' do
      let(:result) { { status: :success, schema: { schema: 'Sample Schema' } } }

      it 'returns the schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq('{"schema":"Sample Schema"}')
      end
    end

    context 'when an error occurs parsing the schema' do
      let(:result) { { status: :error, message: 'Some error occurred' } }

      it 'returns 422 with the error' do
        subject

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(response.body).to eq('{"status":"error","message":"Some error occurred"}')
      end
    end
  end
end
