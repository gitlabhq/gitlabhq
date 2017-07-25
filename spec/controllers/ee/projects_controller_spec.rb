require('spec_helper')

describe ProjectsController do # rubocop:disable RSpec/FilePath
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe 'PUT #update' do
    before do
      controller.instance_variable_set(:@project, project)
    end

    it 'updates EE attributes' do
      params = {
        repository_size_limit: 1024
      }

      put :update,
          namespace_id: project.namespace,
          id: project.id,
          project: params

      expect(response).to have_http_status(302)
      params.except(:repository_size_limit).each do |param, value|
        expect(project.public_send(param)).to eq(value)
      end
      expect(project.repository_size_limit).to eq(params[:repository_size_limit].megabytes)
    end

    it 'updates Merge Request Approvers attributes' do
      params = {
        approvals_before_merge: 50,
        approver_group_ids: create(:group).id,
        approver_ids: create(:user).id,
        reset_approvals_on_push: false
      }

      put :update,
          namespace_id: project.namespace,
          id: project.id,
          project: params

      expect(response).to have_http_status(302)
      expect(project.approver_groups.pluck(:group_id)).to contain_exactly(params[:approver_group_ids])
      expect(project.approvers.pluck(:user_id)).to contain_exactly(params[:approver_ids])
    end

    it 'updates Issuable Default Templates attributes' do
      params = {
        issues_template: 'You got issues?',
        merge_requests_template: 'I got tissues'
      }

      put :update,
          namespace_id: project.namespace,
          id: project.id,
          project: params

      expect(response).to have_http_status(302)
      params.each do |param, value|
        expect(project.public_send(param)).to eq(value)
      end
    end

    it 'updates Fast Forward Merge attributes' do
      params = {
        merge_method: :ff
      }

      put :update,
          namespace_id: project.namespace,
          id: project.id,
          project: params

      expect(response).to have_http_status(302)
      params.each do |param, value|
        expect(project.public_send(param)).to eq(value)
      end
    end

    it 'updates Fast Forward Merge attributes' do
      params = {
        merge_method: :ff
      }

      put :update,
          namespace_id: project.namespace,
          id: project.id,
          project: params

      expect(response).to have_http_status(302)
      params.each do |param, value|
        expect(project.public_send(param)).to eq(value)
      end
    end

    it 'updates Service Desk attributes' do
      allow(Gitlab::IncomingEmail).to receive(:enabled?) { true }
      allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }
      stub_licensed_features(service_desk: true)
      params = {
        service_desk_enabled: true
      }

      put :update,
          namespace_id: project.namespace,
          id: project.id,
          project: params

      expect(response).to have_http_status(302)
      expect(project.service_desk_enabled).to eq(true)
    end

    context 'repository mirrors licensed' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'updates repository mirror attributes' do
        params = {
          mirror: true,
          mirror_trigger_builds: true,
          mirror_user_id: user.id
        }

        put :update,
            namespace_id: project.namespace,
            id: project.id,
            project: params

        params.each do |param, value|
          expect(project.public_send(param)).to eq(value)
        end
      end
    end

    context 'repository mirrors unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not update repository mirror attributes' do
        params = {
          mirror: true,
          mirror_trigger_builds: true,
          mirror_user_id: user.id
        }

        params.each do |param, _value|
          expect do
            put :update,
                namespace_id: project.namespace,
                id: project.id,
                project: params
          end.not_to change(project, param)
        end
      end
    end
  end
end
