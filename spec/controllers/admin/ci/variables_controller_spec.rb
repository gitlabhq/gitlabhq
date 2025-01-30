# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Ci::VariablesController, feature_category: :ci_variables do
  let_it_be(:variable) { create(:ci_instance_variable) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    subject do
      get :show, params: {}, format: :json
    end

    context 'when signed in as admin' do
      let(:user) { create(:admin) }

      include_examples 'GET #show lists all variables'
    end

    context 'when signed in as regular user' do
      let(:user) { create(:user) }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PATCH #update' do
    subject do
      patch :update,
        params: {
          variables_attributes: variables_attributes
        },
        format: :json
    end

    context 'when signed in as admin' do
      let(:user) { create(:admin) }

      include_examples 'PATCH #update updates variables' do
        let(:variables_scope) { Ci::InstanceVariable.all }
        let(:file_variables_scope) { variables_scope.file }
      end
    end

    context 'when signed in as regular user' do
      let(:user) { create(:user) }

      let(:variables_attributes) do
        [{
          id: variable.id,
          key: variable.key,
          secret_value: 'new value'
        }]
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
