# frozen_string_literal: true

require 'spec_helper'

describe Projects::ManagedLicensesController do
  let(:project) do
    create(:project).tap do |p|
      @software_license_policy = create(:software_license_policy, project: p)
    end
  end

  let(:maintainer_user) do
    create(:user).tap do |u|
      project.add_maintainer(u)
    end
  end

  let(:dev_user) do
    create(:user).tap do |u|
      project.add_developer(u)
    end
  end

  let(:reporter_user) do
    create(:user).tap do |u|
      create(:project_member, :reporter, user: u, project: project)
    end
  end

  let(:other_user) { create(:user) }

  let(:unlogged_user) { nil }

  let(:software_license_policy) do
    @software_license_policy ||= create(:software_license_policy, project: project)
  end

  before do
    stub_licensed_features(license_management: true)
  end

  describe 'GET #index' do
    subject do
      allow(controller).to receive(:current_user).and_return(user)

      get :index, namespace_id: project.namespace.to_param, project_id: project, format: :json
    end

    context 'with license management not available' do
      before do
        stub_licensed_features(license_management: false)
      end
      let(:user) { dev_user }

      it 'returns a not found status' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with a user without read permission' do
      let(:user) { other_user }

      it 'returns a not found status' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with no logged in user' do
      let(:user) { unlogged_user }

      it 'returns an unauthorized status' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with a user with read permissions' do
      let(:user) { dev_user }

      it 'renders the software license policies as json' do
        subject

        expect(response).to match_response_schema('software_license_policies', dir: 'ee')
      end

      it 'has only one software license policy' do
        subject

        expect(json_response['software_license_policies'].count).to eq(1)
      end
    end
  end

  describe 'GET #show' do
    subject do
      allow(controller).to receive(:current_user).and_return(user)

      get :show,
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: software_license_policy.id,
        format: :json
    end

    context 'with a user without read permission' do
      let(:user) { other_user }

      it 'returns a not found status' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with no logged in user' do
      let(:user) { unlogged_user }

      it 'returns an unauthorized status' do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with a user with read permissions' do
      let(:user) { dev_user }

      it 'renders the software license policy as json' do
        subject

        expect(response).to match_response_schema('software_license_policy', dir: 'ee')
      end

      it 'has correct values for its fields' do
        subject

        expect(json_response['name']).to eq(software_license_policy.name)
        expect(json_response['approval_status']).to eq(software_license_policy.approval_status)
      end
    end
  end

  describe 'GET #show with license name as identifier' do
    let(:user) { dev_user }

    subject do
      allow(controller).to receive(:current_user).and_return(user)

      get :show,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: CGI.escape(software_license_policy.name),
          format: :json
    end

    it 'renders the software license policy as json' do
      subject

      expect(response).to match_response_schema('software_license_policy', dir: 'ee')
    end

    it 'has correct values for its fields' do
      subject

      expect(json_response['name']).to eq(software_license_policy.name)
      expect(json_response['approval_status']).to eq(software_license_policy.approval_status)
    end
  end

  describe 'POST #create' do
    let(:software_license_policy_attributes) do
      { id: software_license_policy.id,
        name: software_license_policy.name,
        approval_status: software_license_policy.approval_status }
    end

    let(:new_software_license_policy_attributes) do
      { name: 'new_name',
        approval_status: 'blacklisted' }
    end

    subject do
      allow(controller).to receive(:current_user).and_return(user)

      post :create,
        namespace_id: project.namespace.to_param,
        project_id: project,
        managed_license: to_create_software_license_policy_attributes,
        format: :json
    end

    context 'with a user without admin permission' do
      let(:user) { dev_user }

      let(:to_create_software_license_policy_attributes) do
        new_software_license_policy_attributes
      end

      it 'returns a forbidden status' do
        expect { subject }.not_to change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with a user without read permission' do
      let(:user) { other_user }

      let(:to_create_software_license_policy_attributes) do
        new_software_license_policy_attributes
      end

      it 'returns a not found status' do
        expect { subject }.not_to change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with no logged in user' do
      let(:user) { unlogged_user }

      let(:to_create_software_license_policy_attributes) do
        new_software_license_policy_attributes
      end

      it 'returns an unauthorized status' do
        expect { subject }.not_to change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with a user with admin permissions' do
      let(:user) { maintainer_user }

      context 'with duplicate new software license policy parameters' do
        let(:to_create_software_license_policy_attributes) do
          software_license_policy_attributes.merge(approval_status: 'blacklisted')
        end

        it 'does not update the existing software license policy' do
          expect { subject }.not_to change { software_license_policy.reload.approval_status }
        end

        it 'does not create the new software license policy' do
          expect { subject }.not_to change { project.software_license_policies.count }
        end

        it 'returns a bad request status' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with new software license policy parameters' do
        let(:to_create_software_license_policy_attributes) do
          new_software_license_policy_attributes
        end

        it 'creates the new software license policy' do
          expect { subject }.to change { project.software_license_policies.count }.by(1)
        end

        it 'returns an ok status' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'PATCH #update' do
    let(:software_license_policy_attributes) do
      { id: software_license_policy.id,
        name: software_license_policy.name,
        approval_status: software_license_policy.approval_status }
    end

    let(:new_software_license_policy_attributes) do
      { name: 'new_name',
        approval_status: 'blacklisted' }
    end

    let(:modified_software_license_policy_attributes) do
      software_license_policy_attributes.merge(approval_status: 'blacklisted')
    end

    subject do
      allow(controller).to receive(:current_user).and_return(user)

      patch :update,
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: software_license_policy.id,
        managed_license: modified_software_license_policy_attributes,
        format: :json
    end

    context 'with a user without admin permission' do
      let(:user) { dev_user }

      let(:to_create_software_license_policy_attributes) do
        new_software_license_policy_attributes
      end

      it 'returns a forbidden status' do
        expect { subject }.not_to change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with a user without read permission' do
      let(:user) { other_user }

      let(:to_create_software_license_policy_attributes) do
        new_software_license_policy_attributes
      end

      it 'returns a not found status' do
        expect { subject }.not_to change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with no logged in user' do
      let(:user) { unlogged_user }

      let(:to_create_software_license_policy_attributes) do
        new_software_license_policy_attributes
      end

      it 'returns an unauthorized status' do
        expect { subject }.not_to change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with a user with admin permissions' do
      let(:user) { maintainer_user }

      context 'with invalid new software license policy parameters' do
        let(:modified_software_license_policy_attributes) do
          software_license_policy_attributes.merge(approval_status: 3)
        end

        it 'does not update the existing software license policy' do
          expect { subject }.not_to change { software_license_policy.reload.approval_status }
        end

        it 'does not create the new software license policy' do
          expect { subject }.not_to change { project.software_license_policies.count }
        end

        it 'returns a bad request status' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with valid updated software license policy parameters' do
        it 'updates the existing software license policy' do
          expect { subject }.to change { software_license_policy.reload.approval_status }.to('blacklisted')
        end

        it 'does not create a new software license policy' do
          expect { subject }.not_to change { project.software_license_policies.count }
        end

        it 'returns an ok status' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'has the updated software license policies in response' do
          subject

          expect(response).to match_response_schema('software_license_policy', dir: 'ee')
          expect(JSON.parse(response.body)).to eq(modified_software_license_policy_attributes.with_indifferent_access)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:id_to_destroy) { software_license_policy.id }

    subject do
      allow(controller).to receive(:current_user).and_return(user)

      delete :destroy,
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: id_to_destroy,
        format: :json
    end

    context 'with a user without admin permission' do
      let(:user) { dev_user }

      let(:to_create_software_license_policy_attributes) do
        new_software_license_policy_attributes
      end

      it 'returns a forbidden status' do
        expect { subject }.not_to change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with a user without read permission' do
      let(:user) { other_user }

      let(:to_create_software_license_policy_attributes) do
        new_software_license_policy_attributes
      end

      it 'returns a not found status' do
        expect { subject }.not_to change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with no logged in user' do
      let(:user) { unlogged_user }

      let(:to_create_software_license_policy_attributes) do
        new_software_license_policy_attributes
      end

      it 'returns an unauthorized status' do
        expect { subject }.not_to change { project.software_license_policies.count }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with a user with admin permissions' do
      let(:user) { maintainer_user }

      context 'with an existing software license policy' do
        it 'destroys the software license policy' do
          expect { subject }.to change { project.software_license_policies.count }.by(-1)
          expect { software_license_policy.reload }.to raise_error ActiveRecord::RecordNotFound
        end

        it 'returns an ok status' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'has an empty response body' do
          subject

          expect(response.body).to eq("")
        end
      end

      context 'with an unknown software license policy' do
        let(:id_to_destroy) { 12341234 }

        it 'does not destroy any software license policy' do
          expect { subject }.not_to change { project.software_license_policies.count }
          expect { software_license_policy.reload }.not_to raise_error
        end

        it 'returns a not found status' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
