# frozen_string_literal: true

require 'spec_helper'

describe API::ManagedLicenses do
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

  let(:software_license_policy) do
    @software_license_policy ||= create(:software_license_policy, project: project)
  end

  before do
    stub_licensed_features(license_management: true)
  end

  describe 'GET /projects/:id/managed_licenses' do
    context 'with license management not available' do
      before do
        stub_licensed_features(license_management: false)
      end

      it 'returns a forbidden status' do
        get api("/projects/#{project.id}/managed_licenses", dev_user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user with proper permissions' do
      it 'returns project managed licenses' do
        get api("/projects/#{project.id}/managed_licenses", dev_user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_a(Array)
        expect(json_response.first['id']).to eq(software_license_policy.id)
        expect(json_response.first['name']).to eq(software_license_policy.name)
        expect(json_response.first['approval_status']).to eq(software_license_policy.approval_status)
      end
    end

    context 'authorized user without read permissions' do
      it 'returns project managed licenses to users with read permissions' do
        get api("/projects/#{project.id}/managed_licenses", reporter_user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_a(Array)
        expect(json_response.first['id']).to eq(software_license_policy.id)
        expect(json_response.first['name']).to eq(software_license_policy.name)
        expect(json_response.first['approval_status']).to eq(software_license_policy.approval_status)
      end
    end

    context 'unauthorized user' do
      it 'does not return project managed licenses' do
        get api("/projects/#{project.id}/managed_licenses")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /projects/:id/managed_licenses/:managed_license_id' do
    context 'authorized user with proper permissions' do
      it 'returns project managed license details' do
        get api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", dev_user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(software_license_policy.id)
        expect(json_response['name']).to eq(software_license_policy.name)
        expect(json_response['approval_status']).to eq(software_license_policy.approval_status)
      end

      it 'returns project managed license details using the license name as key' do
        escaped_name = CGI.escape(software_license_policy.name)
        get api("/projects/#{project.id}/managed_licenses/#{escaped_name}", dev_user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(software_license_policy.id)
        expect(json_response['name']).to eq(software_license_policy.name)
        expect(json_response['approval_status']).to eq(software_license_policy.approval_status)
      end

      it 'responds with 404 Not Found if requesting non-existing managed license' do
        get api("/projects/#{project.id}/managed_licenses/1234512345", dev_user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authorized user with read permissions' do
      it 'returns project managed license details' do
        get api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", reporter_user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['id']).to eq(software_license_policy.id)
        expect(json_response['name']).to eq(software_license_policy.name)
        expect(json_response['approval_status']).to eq(software_license_policy.approval_status)
      end
    end

    context 'unauthorized user' do
      it 'does not return project managed license details' do
        get api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'POST /projects/:id/managed_licenses' do
    context 'authorized user with proper permissions' do
      it 'creates managed license' do
        expect do
          post api("/projects/#{project.id}/managed_licenses", maintainer_user),
            name: 'NEW_LICENSE_NAME',
            approval_status: 'approved'
        end.to change {project.software_license_policies.count}.by(1)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response).to have_key('id')
        expect(json_response['name']).to eq('NEW_LICENSE_NAME')
        expect(json_response['approval_status']).to eq('approved')
      end

      it 'does not allow to duplicate managed license name' do
        expect do
          post api("/projects/#{project.id}/managed_licenses", maintainer_user),
            name: software_license_policy.name,
            approval_status: 'blacklisted'
        end.not_to change {project.software_license_policies.count}

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'authorized user with read permissions' do
      it 'does not create managed license' do
        post api("/projects/#{project.id}/managed_licenses", dev_user),
          name: 'NEW_LICENSE_NAME',
          approval_status: 'approved'

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user without permissions' do
      it 'does not create managed license' do
        post api("/projects/#{project.id}/managed_licenses", reporter_user),
          name: 'NEW_LICENSE_NAME',
          approval_status: 'approved'

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it 'does not create managed license' do
        post api("/projects/#{project.id}/managed_licenses"),
          name: 'NEW_LICENSE_NAME',
          approval_status: 'approved'

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'PATCH /projects/:id/managed_licenses/:managed_license_id' do
    context 'authorized user with proper permissions' do
      it 'updates managed license data' do
        initial_license = project.software_license_policies.first
        initial_id = initial_license.id
        initial_name = initial_license.name
        initial_approval_status = initial_license.approval_status
        patch api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", maintainer_user),
          approval_status: 'blacklisted'

        updated_software_license_policy = project.software_license_policies.reload.first

        expect(response).to have_gitlab_http_status(200)

        # Check that response is equal to the updated object
        expect(json_response['id']).to eq(initial_id)
        expect(json_response['name']).to eq(updated_software_license_policy.name)
        expect(json_response['approval_status']).to eq(updated_software_license_policy.approval_status)

        # Check that the approval status was updated
        expect(updated_software_license_policy.approval_status).to eq('blacklisted')

        # Check that response is equal to the old object except for the approval status
        expect(initial_id).to eq(updated_software_license_policy.id)
        expect(initial_name).to eq(updated_software_license_policy.name)
        expect(initial_approval_status).not_to eq(updated_software_license_policy.approval_status)
      end

      it 'responds with 404 Not Found if requesting non-existing managed license' do
        patch api("/projects/#{project.id}/managed_licenses/1234512345", maintainer_user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'authorized user with read permissions' do
      it 'does not update managed license' do
        patch api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", dev_user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user without permissions' do
      it 'does not update managed license' do
        patch api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", reporter_user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'unauthorized user' do
      it 'does not update managed license' do
        patch api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}")

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'DELETE /projects/:id/managed_licenses/:managed_license_id' do
    context 'authorized user with proper permissions' do
      it 'deletes managed license' do
        expect do
          delete api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", maintainer_user)

          expect(response).to have_gitlab_http_status(204)
        end.to change {project.software_license_policies.count}.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing managed license' do
        expect do
          delete api("/projects/#{project.id}/managed_licenses/1234512345", maintainer_user)

          expect(response).to have_gitlab_http_status(404)
        end.not_to change {project.software_license_policies.count}
      end
    end

    context 'authorized user with read permissions' do
      it 'does not delete managed license' do
        expect do
          delete api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", dev_user)

          expect(response).to have_gitlab_http_status(403)
        end.not_to change {project.software_license_policies.count}
      end
    end

    context 'authorized user without permissions' do
      it 'does not delete managed license' do
        expect do
          delete api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}", reporter_user)

          expect(response).to have_gitlab_http_status(403)
        end.not_to change {project.software_license_policies.count}
      end
    end

    context 'unauthorized user' do
      it 'does not delete managed license' do
        expect do
          delete api("/projects/#{project.id}/managed_licenses/#{software_license_policy.id}")

          expect(response).to have_gitlab_http_status(401)
        end.not_to change {project.software_license_policies.count}
      end
    end
  end
end
