require 'spec_helper'

describe Projects::VariablesController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_master(user)
  end

  describe 'GET #show' do
    let(:variable) { create(:ci_variable) }

    before do
      project.variables << variable
    end

    subject do
      get :show, namespace_id: project.namespace.to_param, project_id: project,
                 format: :json
    end

    it 'renders the ci_variable as json' do
      subject

      expect(response).to match_response_schema('variable')
    end
  end

  describe 'POST #update' do
    let(:variable) { create(:ci_variable) }

    before do
      project.variables << variable
    end

    context 'with invalid new variable parameters' do
      subject do
        patch :update,
          namespace_id: project.namespace.to_param, project_id: project,
          variables_attributes: [{ id: variable.id, key: variable.key,
                                   value: 'other_value',
                                   protected: variable.protected?.to_s },
                                 { key: '..?', value: 'dummy_value',
                                   protected: 'false' }],
          format: :json
      end

      it 'does not update the existing variable' do
        expect { subject }.not_to change { variable.reload.value }
      end

      it 'does not create the new variable' do
        expect { subject }.not_to change { project.variables.count }
      end

      it 'returns a bad request response' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with valid new variable parameters' do
      subject do
        patch :update,
          namespace_id: project.namespace.to_param, project_id: project,
          variables_attributes: [{ id: variable.id, key: variable.key,
                                   value: 'other_value',
                                   protected: variable.protected?.to_s },
                                 { key: 'new_key', value: 'dummy_value',
                                   protected: 'false' }],
          format: :json
      end

      it 'updates the existing variable' do
        expect { subject }.to change { variable.reload.value }.to('other_value')
      end

      it 'creates the new variable' do
        expect { subject }.to change { project.variables.count }.by(1)
      end

      it 'returns a successful response' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'has all variables in response' do
        subject

        expect(response).to match_response_schema('variable')
      end
    end

    context 'with a deleted variable' do
      subject do
        patch :update,
          namespace_id: project.namespace.to_param, project_id: project,
          variables_attributes: [{ id: variable.id, key: variable.key,
                                   value: variable.value,
                                   protected: variable.protected?.to_s,
                                   _destroy: 'true' }],
          format: :json
      end

      it 'destroys the variable' do
        expect { subject }.to change { project.variables.count }.by(-1)
        expect { variable.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'returns a successful response' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'has all variables in response' do
        subject

        expect(json_response['variables'].count).to eq(0)
      end
    end
  end
end
