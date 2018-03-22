require 'spec_helper'

describe Groups::VariablesController do
  include ExternalAuthorizationServiceHelpers
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let(:variable) { create(:ci_group_variable, group: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with external authorization enabled' do
    before do
      enable_external_authorization_service_check
    end

    describe 'GET #show' do
      let!(:variable) { create(:ci_group_variable, group: group) }

      it 'is successful' do
        get :show, group_id: group, format: :json

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'PATCH #update' do
      let!(:variable) { create(:ci_group_variable, group: group) }
      let(:owner) { group }

      it 'is successful' do
        patch :update,
              group_id: group,
              variables_attributes: [{ id: variable.id, key: 'hello' }],
              format: :json

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end
end
