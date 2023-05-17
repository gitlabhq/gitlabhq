# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::BranchesController, feature_category: :integrations do
  describe '#new' do
    context 'when logged in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'assigns the suggested branch name' do
        get :new, params: { issue_key: 'ACME-123', issue_summary: 'My Issue !@#$%' }

        expect(response).to be_successful
        expect(assigns(:new_branch_data)).to include(
          initial_branch_name: 'ACME-123-my-issue',
          success_state_svg_path: start_with('/assets/illustrations/empty-state/empty-merge-requests-md-')
        )
      end

      it 'ignores missing summary' do
        get :new, params: { issue_key: 'ACME-123' }

        expect(response).to be_successful
        expect(assigns(:new_branch_data)).to include(initial_branch_name: 'ACME-123')
      end

      it 'does not set a branch name if key is not passed' do
        get :new, params: { issue_summary: 'My issue' }

        expect(response).to be_successful
        expect(assigns(:new_branch_data)).to include('initial_branch_name': nil)
      end
    end

    context 'when not logged in' do
      it 'redirects to the login page' do
        get :new

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
