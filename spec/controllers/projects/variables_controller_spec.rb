# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::VariablesController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET #show' do
    let!(:variable) { create(:ci_variable, project: project) }

    subject do
      get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json
    end

    include_examples 'GET #show lists all variables'
  end

  describe 'PATCH #update' do
    let!(:variable) { create(:ci_variable, project: project) }
    let(:owner) { project }

    subject do
      patch :update,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          variables_attributes: variables_attributes
        },
        format: :json
    end

    include_examples 'PATCH #update updates variables'

    context 'with environment scope' do
      let!(:variable) { create(:ci_variable, project: project, environment_scope: 'custom_scope') }

      let(:variable_attributes) do
        { id: variable.id,
          key: variable.key,
          secret_value: variable.value,
          protected: variable.protected?.to_s,
          environment_scope: variable.environment_scope }
      end

      let(:new_variable_attributes) do
        { key: 'new_key',
          secret_value: 'dummy_value',
          protected: 'false',
          environment_scope: 'new_scope' }
      end

      context 'with same key and different environment scope' do
        let(:variables_attributes) do
          [
            variable_attributes,
            new_variable_attributes.merge(key: variable.key)
          ]
        end

        it 'does not update the existing variable' do
          expect { subject }.not_to change { variable.reload.value }
        end

        it 'creates the new variable' do
          expect { subject }.to change { owner.variables.count }.by(1)
        end

        it 'returns a successful response including all variables' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('variables')
        end
      end

      context 'with same key and same environment scope' do
        let(:variables_attributes) do
          [
            variable_attributes,
            new_variable_attributes.merge(key: variable.key, environment_scope: variable.environment_scope)
          ]
        end

        it 'does not update the existing variable' do
          expect { subject }.not_to change { variable.reload.value }
        end

        it 'does not create the new variable' do
          expect { subject }.not_to change { owner.variables.count }
        end

        it 'returns a bad request response' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end
end
