require 'spec_helper'

describe Projects::Settings::RepositoryController do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe 'GET show' do
    context 'push rule' do
      subject(:push_rule) { assigns(:push_rule) }

      it 'is created' do
        get :show, namespace_id: project.namespace, project_id: project

        is_expected.to be_persisted
      end

      context 'unlicensed' do
        before do
          stub_licensed_features(push_rules: false)
        end

        it 'is not created' do
          get :show, namespace_id: project.namespace, project_id: project

          is_expected.to be_nil
        end
      end
    end
  end
end
