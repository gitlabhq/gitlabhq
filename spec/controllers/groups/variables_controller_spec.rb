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
    let(:variable) { create(:ci_group_variable) }

    context 'updating a variable with valid characters' do
      before do
        group.variables << variable
      end

      it 'shows a success flash message' do
        post :update, group_id: group,
                      id: variable.id, variable: { key: variable.key, value: 'two' }

        expect(flash[:notice]).to include 'Variable was successfully updated.'
        expect(response).to redirect_to(group_variables_path(group))
      end

      it 'renders the action #show if the variable key is invalid' do
        post :update, group_id: group,
                      id: variable.id, variable: { key: '?', value: variable.value }

        expect(response).to have_http_status(200)
        expect(response).to render_template :show
      end
    end
  end
end
