require 'spec_helper'

describe Projects::VariablesController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_master(user)

    allow_any_instance_of(License).to receive(:feature_available?).and_call_original
    allow_any_instance_of(License).to receive(:feature_available?).with(:variable_environment_scope).and_return(true)
  end

  describe 'PATCH #update' do
    let!(:variable) { create(:ci_variable, project: project) }
    let(:owner) { project }

    subject do
      patch :update,
        namespace_id: project.namespace.to_param,
        project_id: project,
        variables_attributes: variables_attributes,
        format: :json
    end

    context 'with same key and different environment scope' do
      let(:variable_attributes) do
        { id: variable.id,
          key: variable.key,
          value: variable.value,
          protected: variable.protected?.to_s,
          environment_scope: variable.environment_scope }
      end
      let(:new_variable_attributes) do
        { key: variable.key,
          value: 'dummy_value',
          protected: 'false',
          environment_scope: 'prod' }
      end
      let(:variables_attributes) do
        [
          variable_attributes,
          new_variable_attributes
        ]
      end

      it 'does not update the existing variable' do
        expect { subject }.not_to change { variable.reload.value }
      end

      it 'creates the new variable' do
        expect { subject }.to change { owner.variables.count }.by(1)
      end

      it 'returns a successful response' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'has all variables in response' do
        subject

        expect(response).to match_response_schema('variables')
      end
    end
  end
end
