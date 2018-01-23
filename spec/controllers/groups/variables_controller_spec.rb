require 'spec_helper'

describe Groups::VariablesController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    group.add_master(user)
  end

  describe 'POST #create' do
    context 'variable is valid' do
      it 'shows a success flash message' do
        post :create, group_id: group, variable: { key: "one", value: "two" }

        expect(flash[:notice]).to include 'Variable was successfully created.'
        expect(response).to redirect_to(group_settings_ci_cd_path(group))
      end
    end

    context 'variable is invalid' do
      it 'renders show' do
        post :create, group_id: group, variable: { key: "..one", value: "two" }

        expect(response).to render_template("groups/variables/show")
      end
    end
  end

  describe 'POST #update' do
    let!(:variable) { create(:ci_group_variable, group: group) }

    context 'updating a variable with valid characters' do
      it 'shows a success flash message' do
        post :update, group_id: group,
                      id: variable.id, variable: { key: variable.key, value: 'two' }

        expect(flash[:notice]).to include 'Variable was successfully updated.'
        expect(response).to redirect_to(group_variables_path(group))
      end

      it 'renders the action #show if the variable key is invalid' do
        post :update, group_id: group,
                      id: variable.id, variable: { key: '?', value: variable.value }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template :show
      end
    end
  end

  describe 'POST #save_multiple' do
    let!(:variable) { create(:ci_group_variable, group: group) }

    context 'with invalid new variable parameters' do
      subject do
        post :save_multiple,
          group_id: group,
          variables_attributes: [{ id: variable.id, key: variable.key, value: 'other_value' },
                                 { key: '..?', value: 'dummy_value' }],
          format: :json
      end

      it 'does not update the existing variable' do
        expect { subject }.not_to change { variable.reload.value }
      end

      it 'does not create the new variable' do
        expect { subject }.not_to change { group.variables.count }
      end

      it 'returns a bad request response' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with valid new variable parameters' do
      subject do
        post :save_multiple,
          group_id: group,
          variables_attributes: [{ id: variable.id, key: variable.key, value: 'other_value' },
                                 { key: 'new_key', value: 'dummy_value' }],
          format: :json
      end

      it 'updates the existing variable' do
        expect { subject }.to change { variable.reload.value }.to('other_value')
      end

      it 'creates the new variable' do
        expect { subject }.to change { group.variables.count }.by(1)
      end

      it 'returns a successful response' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with a deleted variable' do
      subject do
        post :save_multiple,
          group_id: group,
          variables_attributes: [{ id: variable.id, key: variable.key,
                                   value: variable.value, _destroy: 'true' }],
          format: :json
      end

      it 'destroys the variable' do
        expect { subject }.to change { group.variables.count }.by(-1)
        expect { variable.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'returns a successful response' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
