require 'spec_helper'

describe Projects::VariablesController do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_master(user)
  end

  describe 'GET #show' do
    let!(:variable) { create(:ci_variable, project: project) }

    subject do
      get :show, namespace_id: project.namespace.to_param, project_id: project, format: :json
    end

    include_examples 'GET #show lists all variables'
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

    include_examples 'PATCH #update updates variables'
  end
end
