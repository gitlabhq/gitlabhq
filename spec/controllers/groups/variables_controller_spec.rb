# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::VariablesController do
  include ExternalAuthorizationServiceHelpers

  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    group.add_maintainer(user)
  end

  describe 'GET #show' do
    let!(:variable) { create(:ci_group_variable, group: group) }

    subject do
      get :show, params: { group_id: group }, format: :json
    end

    include_examples 'GET #show lists all variables'
  end

  describe 'PATCH #update' do
    let!(:variable) { create(:ci_group_variable, group: group) }
    let(:owner) { group }

    subject do
      patch :update,
        params: {
          group_id: group,
          variables_attributes: variables_attributes
        },
        format: :json
    end

    include_examples 'PATCH #update updates variables'
  end

  context 'with external authorization enabled' do
    before do
      enable_external_authorization_service_check
    end

    describe 'GET #show' do
      let!(:variable) { create(:ci_group_variable, group: group) }

      it 'is successful' do
        get :show, params: { group_id: group }, format: :json

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'PATCH #update' do
      let!(:variable) { create(:ci_group_variable, group: group) }
      let(:owner) { group }

      it 'is successful' do
        patch :update,
              params: {
                group_id: group,
                variables_attributes: [{ id: variable.id, key: 'hello' }]
              },
              format: :json

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
