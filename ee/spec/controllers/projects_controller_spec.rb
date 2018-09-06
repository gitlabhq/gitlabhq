require 'spec_helper'

describe ProjectsController do
  include ExternalAuthorizationServiceHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'POST create' do
    let!(:params) do
      {
        path: 'foo',
        description: 'bar',
        import_url: project.http_url_to_repo,
        namespace_id: user.namespace.id,
        visibility_level: Gitlab::VisibilityLevel::PUBLIC,
        mirror: true,
        mirror_trigger_builds: true
      }
    end

    context 'with licensed repository mirrors' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'has mirror enabled in new project' do
        post :create, project: params

        created_project = Project.find_by_path('foo')
        expect(created_project.reload.mirror).to be true
        expect(created_project.reload.mirror_user.id).to eq(user.id)
      end
    end

    context 'with unlicensed repository mirrors' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'has mirror disabled in new project' do
        post :create, project: params

        created_project = Project.find_by_path('foo')
        expect(created_project.reload.mirror).to be false
        expect(created_project.reload.mirror_user).to be nil
      end
    end

    context 'custom project templates' do
      let(:group) { create(:group) }
      let(:project_template) { create(:project, :repository, :public, namespace: group) }
      let(:templates_params) do
        {
          path: 'foo',
          description: 'bar',
          namespace_id: user.namespace.id,
          use_custom_template: true,
          template_name: project_template.name
        }
      end

      context 'when licensed' do
        before do
          stub_licensed_features(custom_project_templates: true)
          stub_ee_application_setting(custom_project_templates_group_id: group.id)
        end

        context 'object storage' do
          before do
            stub_uploads_object_storage(FileUploader)
          end

          it 'creates the project from project template' do
            post :create, project: templates_params

            created_project = Project.find_by_path('foo')
            expect(flash[:notice]).to eq "Project 'foo' was successfully created."
            expect(created_project.repository.empty?).to be false
          end
        end
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(custom_project_templates: false)
        end

        it 'creates the project from project template' do
          post :create, project: templates_params

          created_project = Project.find_by_path('foo')
          expect(flash[:notice]).to eq "Project 'foo' was successfully created."
          expect(created_project.repository.empty?).to be true
        end
      end
    end
  end

  describe 'PUT #update' do
    it 'updates EE attributes' do
      params = {
        repository_size_limit: 1024
      }

      put :update,
          namespace_id: project.namespace,
          id: project,
          project: params
      project.reload

      expect(response).to have_gitlab_http_status(302)
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
          id: project,
          project: params
      project.reload

      expect(response).to have_gitlab_http_status(302)
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
          id: project,
          project: params
      project.reload

      expect(response).to have_gitlab_http_status(302)
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
          id: project,
          project: params
      project.reload

      expect(response).to have_gitlab_http_status(302)
      expect(project.service_desk_enabled).to eq(true)
    end

    context 'repository mirrors' do
      let(:params) do
        {
          mirror: true,
          mirror_trigger_builds: true,
          mirror_user_id: user.id,
          import_url: 'https://example.com'
        }
      end

      context 'when licensed' do
        before do
          stub_licensed_features(repository_mirrors: true)
        end

        it 'updates repository mirror attributes' do
          expect_any_instance_of(EE::Project).to receive(:force_import_job!).once

          put :update,
            namespace_id: project.namespace,
            id: project,
            project: params
          project.reload

          expect(project.mirror).to eq(true)
          expect(project.mirror_trigger_builds).to eq(true)
          expect(project.mirror_user).to eq(user)
          expect(project.import_url).to eq('https://example.com')
        end
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(repository_mirrors: false)
        end

        it 'does not update repository mirror attributes' do
          params.each do |param, _value|
            expect do
              put :update,
                namespace_id: project.namespace,
                id: project,
                project: params
              project.reload
            end.not_to change(project, param)
          end
        end
      end
    end

    it_behaves_like 'unauthorized when external service denies access' do
      subject do
        put :update,
            namespace_id: project.namespace,
            id: project,
            project: { description: 'Hello world' }
        project.reload
      end

      it 'updates when the service allows access' do
        external_service_allow_access(user, project)

        expect { subject }.to change(project, :description)
      end

      it 'does not update when the service rejects access' do
        external_service_deny_access(user, project)

        expect { subject }.not_to change(project, :description)
      end
    end
  end
end
