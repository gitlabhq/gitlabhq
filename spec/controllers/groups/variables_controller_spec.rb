# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::VariablesController do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:variable) { create(:ci_group_variable, group: group) }

  let(:access_level) { :owner }

  before do
    sign_in(user)
    group.add_user(user, access_level)
  end

  describe 'GET #show' do
    subject do
      get :show, params: { group_id: group }, format: :json
    end

    include_examples 'GET #show lists all variables'

    context 'when the user is a maintainer' do
      let(:access_level) { :maintainer }

      it 'returns not found response' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PATCH #update' do
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

    context 'when the user is a maintainer' do
      let(:access_level) { :maintainer }
      let(:variables_attributes) do
        [{ id: variable.id, key: 'new_key' }]
      end

      it 'returns not found response' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'with external authorization enabled' do
    before do
      enable_external_authorization_service_check
    end

    describe 'GET #show' do
      it 'is successful' do
        get :show, params: { group_id: group }, format: :json

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'PATCH #update' do
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
