require 'spec_helper'

describe Projects::VariablesController do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  describe 'POST #create' do
    context 'variable is valid' do
      it 'shows a success flash message' do
        post :create, namespace_id: project.namespace.to_param, project_id: project,
                      variable: { key: "one", value: "two" }

        expect(flash[:notice]).to include 'Variables were successfully updated.'
        expect(response).to redirect_to(namespace_project_settings_ci_cd_path(project.namespace, project))
      end
    end

    context 'variable is invalid' do
      it 'shows an alert flash message' do
        post :create, namespace_id: project.namespace.to_param, project_id: project,
                      variable: { key: "..one", value: "two" }

        expect(response).to render_template("projects/variables/show")
      end
    end
  end

  describe 'POST #update' do
    let(:variable) { create(:ci_variable) }

    context 'updating a variable with valid characters' do
      before do
        variable.gl_project_id = project.id
        project.variables << variable
      end

      it 'shows a success flash message' do
        post :update, namespace_id: project.namespace.to_param, project_id: project,
                      id: variable.id, variable: { key: variable.key, value: 'two' }

        expect(flash[:notice]).to include 'Variable was successfully updated.'
        expect(response).to redirect_to(namespace_project_variables_path(project.namespace, project))
      end

      it 'renders the action #show if the variable key is invalid' do
        post :update, namespace_id: project.namespace.to_param, project_id: project,
                      id: variable.id, variable: { key: '?', value: variable.value }

        expect(response).to have_http_status(200)
        expect(response).to render_template :show
      end
    end
  end
end
