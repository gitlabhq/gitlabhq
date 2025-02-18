# frozen_string_literal: true

require('spec_helper')

RSpec.describe Projects::Settings::CiCdController, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :allow_runner_registration_token) }
  let_it_be(:project_auto_devops) { create(:project_auto_devops, project: project) }

  context 'as a maintainer' do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    describe 'GET show' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }
      let_it_be(:other_project) { create(:project, group: group) }

      subject { get :show, params: { namespace_id: project.namespace, project_id: project } }

      it 'renders show with 200 status code' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:show)
      end

      context 'with CI/CD disabled' do
        before do
          project.project_feature.update_attribute(:builds_access_level, ProjectFeature::DISABLED)
        end

        it 'renders show with 404 status code' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with assignable project runners' do
        let(:project_runner) { create(:ci_runner, :project, projects: [other_project]) }

        before do
          group.add_maintainer(user)
        end

        it 'sets assignable project runners' do
          subject

          expect(assigns(:assignable_runners)).to contain_exactly(project_runner)
        end
      end

      context 'with project runners' do
        let(:project_runner) { create(:ci_runner, :project, projects: [project]) }

        it 'sets project runners' do
          subject

          expect(assigns(:project_runners)).to contain_exactly(project_runner)
        end
      end

      context 'with group runners' do
        let(:project) { other_project }
        let!(:group_runner) { create(:ci_runner, :group, groups: [group]) }

        it 'sets group runners' do
          subject

          expect(assigns(:group_runners_count)).to be(1)
          expect(assigns(:group_runners)).to contain_exactly(group_runner)
        end
      end

      context 'with instance runners' do
        let_it_be(:shared_runner) { create(:ci_runner, :instance) }

        it 'sets shared runners' do
          subject

          expect(assigns(:shared_runners_count)).to be(1)
          expect(assigns(:shared_runners)).to contain_exactly(shared_runner)
        end
      end

      context 'prevents N+1 queries for tags' do
        render_views

        def show
          get :show, params: { namespace_id: project.namespace, project_id: project }
        end

        it 'has the same number of queries with one tag or with many tags', :request_store do
          group.add_maintainer(user)

          show # warmup

          # with one tag
          create(:ci_runner, :instance, tag_list: %w[shared_runner])
          create(:ci_runner, :project, projects: [other_project], tag_list: %w[project_runner])
          create(:ci_runner, :group, groups: [group], tag_list: %w[group_runner])
          control = ActiveRecord::QueryRecorder.new { show }

          # with several tags
          create(:ci_runner, :instance, tag_list: %w[shared_runner tag2 tag3])
          create(:ci_runner, :project, projects: [other_project], tag_list: %w[project_runner tag2 tag3])
          create(:ci_runner, :group, groups: [group], tag_list: %w[group_runner tag2 tag3])

          expect { show }.not_to exceed_query_limit(control)
        end
      end

      context 'when user is authorized to access this action' do
        before do
          project.add_maintainer(user)
        end

        it 'returns a success header' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the user is not authorized to access this action' do
        before do
          project.add_guest(user)
        end

        it 'returns not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe '#reset_cache' do
      subject { post :reset_cache, params: { namespace_id: project.namespace, project_id: project }, format: :json }

      before do
        sign_in(user)
      end

      context 'when logged in as a maintainer' do
        before do
          project.add_maintainer(user)

          allow(ResetProjectCacheService).to receive_message_chain(:new, :execute).and_return(true)
        end

        it 'calls reset project cache service' do
          expect(ResetProjectCacheService).to receive_message_chain(:new, :execute)

          subject
        end

        context 'when service returns successfully' do
          it 'returns a success header' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when service does not return successfully' do
          before do
            allow(ResetProjectCacheService).to receive_message_chain(:new, :execute).and_return(false)
          end

          it 'returns an error header' do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when the user is not authorized to access this action' do
        before do
          project.add_guest(user)
        end

        it 'returns not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'PUT #reset_registration_token' do
      subject { put :reset_registration_token, params: { namespace_id: project.namespace, project_id: project } }

      it 'resets runner registration token' do
        expect { subject }.to change { project.reload.runners_token }
        expect(flash[:toast]).to eq('New runners registration token has been generated!')
      end

      it 'redirects the user to admin runners page' do
        subject

        expect(response).to redirect_to(namespace_project_settings_ci_cd_path)
      end
    end

    describe 'PATCH update' do
      let(:params) { { ci_config_path: '' } }

      subject do
        patch :update, params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          project: params
        }
      end

      it 'redirects to the settings page' do
        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(flash[:toast]).to eq("Pipelines settings for '#{project.name}' were successfully updated.")
      end

      context 'when updating the auto_devops settings' do
        let(:params) { { auto_devops_attributes: { enabled: '' } } }

        context 'following the instance default' do
          let(:params) { { auto_devops_attributes: { enabled: '' } } }

          it 'allows enabled to be set to nil' do
            subject
            project_auto_devops.reload

            expect(project_auto_devops.enabled).to be_nil
          end
        end

        context 'when run_auto_devops_pipeline is true' do
          before do
            expect_next_instance_of(Projects::UpdateService) do |instance|
              expect(instance).to receive(:run_auto_devops_pipeline?).and_return(true)
            end
          end

          context 'when the project repository is empty' do
            it 'sets a notice flash' do
              subject

              expect(controller).to set_flash[:notice]
            end

            it 'does not queue a CreatePipelineWorker' do
              expect(CreatePipelineWorker).not_to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

              subject
            end
          end

          context 'when the project repository is not empty' do
            let(:project) { create(:project, :repository) }

            it 'displays a toast message' do
              allow(CreatePipelineWorker).to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

              subject

              expect(controller).to set_flash[:toast]
            end

            it 'queues a CreatePipelineWorker' do
              expect(CreatePipelineWorker).to receive(:perform_async).with(project.id, user.id, project.default_branch, :web, any_args)

              subject
            end

            it 'creates a pipeline', :sidekiq_inline do
              project.repository.create_file(user, 'Gemfile', 'Gemfile contents', message: 'Add Gemfile', branch_name: 'master')

              expect { subject }.to change { Ci::Pipeline.count }.by(1)
            end
          end
        end

        context 'when run_auto_devops_pipeline is not true' do
          before do
            expect_next_instance_of(Projects::UpdateService) do |instance|
              expect(instance).to receive(:run_auto_devops_pipeline?).and_return(false)
            end
          end

          it 'does not queue a CreatePipelineWorker' do
            expect(CreatePipelineWorker).not_to receive(:perform_async).with(project.id, user.id, :web, any_args)

            subject
          end
        end
      end

      context 'when updating general settings' do
        context 'when build_timeout_human_readable is not specified' do
          let(:params) { { build_timeout_human_readable: '' } }

          it 'set default timeout' do
            subject

            project.reload
            expect(project.build_timeout).to eq(3600)
          end
        end

        context 'when build_timeout_human_readable is specified' do
          let(:params) { { build_timeout_human_readable: '1h 30m' } }

          it 'set specified timeout' do
            subject

            project.reload
            expect(project.build_timeout).to eq(5400)
          end
        end

        context 'when build_timeout_human_readable is invalid' do
          let(:params) { { build_timeout_human_readable: '5m' } }

          it 'set specified timeout' do
            subject

            expect(controller).to set_flash[:alert]
            expect(response).to redirect_to(namespace_project_settings_ci_cd_path)
          end
        end

        context 'when default_git_depth is not specified' do
          let(:params) { { ci_cd_settings_attributes: { default_git_depth: 10 } } }

          before do
            project.ci_cd_settings.update!(default_git_depth: nil)
          end

          it 'set specified git depth' do
            subject

            project.reload
            expect(project.ci_default_git_depth).to eq(10)
          end
        end

        context 'when forward_deployment_enabled is not specified' do
          let(:params) { { ci_cd_settings_attributes: { forward_deployment_enabled: false } } }

          before do
            project.ci_cd_settings.update!(forward_deployment_enabled: nil)
          end

          it 'sets forward deployment enabled' do
            subject

            project.reload
            expect(project.ci_forward_deployment_enabled).to eq(false)
          end
        end

        context 'when changing forward_deployment_rollback_allowed' do
          let(:params) { { ci_cd_settings_attributes: { forward_deployment_rollback_allowed: false } } }

          it 'changes forward deployment rollback allowed' do
            expect { subject }.to change { project.reload.ci_forward_deployment_rollback_allowed }.from(true).to(false)
          end
        end

        context 'when delete_pipelines_in_human_readable is specified' do
          let(:params) { { ci_cd_settings_attributes: { delete_pipelines_in_human_readable: '1 week' } } }

          context 'and user is a maintainer' do
            it 'does not set delete_pipelines_in_human_readable' do
              subject

              project.reload
              expect(project.ci_delete_pipelines_in_seconds).to be_nil
            end
          end

          context 'and user is an owner' do
            it 'sets delete_pipelines_in_human_readable' do
              project.add_owner(user)

              subject

              project.reload
              expect(project.ci_delete_pipelines_in_seconds).to eq(1.week)
            end
          end
        end

        context 'when max_artifacts_size is specified' do
          let(:params) { { max_artifacts_size: 10 } }

          context 'and user is not an admin' do
            it 'does not set max_artifacts_size' do
              subject

              project.reload
              expect(project.max_artifacts_size).to be_nil
            end
          end

          context 'and user is an admin' do
            let(:user) { create(:admin)  }

            context 'with admin mode disabled' do
              it 'does not set max_artifacts_size' do
                subject

                project.reload
                expect(project.max_artifacts_size).to be_nil
              end
            end

            context 'with admin mode enabled', :enable_admin_mode do
              it 'sets max_artifacts_size' do
                subject

                project.reload
                expect(project.max_artifacts_size).to eq(10)
              end
            end
          end
        end
      end

      context 'when user is authorized to access this action' do
        before do
          project.add_maintainer(user)
        end

        it 'returns a success header' do
          subject

          expect(response).to redirect_to(project_settings_ci_cd_path(project))
        end
      end

      context 'when the user is not authorized to access this action' do
        before do
          project.add_guest(user)
        end

        it 'returns not found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'GET #runner_setup_scripts' do
      it 'renders the setup scripts' do
        get :runner_setup_scripts, params: { os: 'linux', arch: 'amd64', namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to have_key("install")
        expect(json_response).to have_key("register")
      end

      it 'renders errors if they occur' do
        get :runner_setup_scripts, params: { os: 'foo', arch: 'bar', namespace_id: project.namespace, project_id: project }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to have_key("errors")
      end
    end

    describe 'GET #export_job_token_authorizations' do
      subject(:get_authorizations) do
        get :export_job_token_authorizations, params: {
          namespace_id: project.namespace,
          project_id: project
        }, format: :csv
      end

      let!(:authorizations) do
        create_list(:ci_job_token_authorization, 3, accessed_project: project)
      end

      context 'when the export is successful' do
        it 'renders the CSV' do
          get_authorizations

          expect(response).to have_gitlab_http_status(:ok)
          rows = response.body.lines

          expect(rows[0]).to include('Origin Project Path,Last Authorized At (UTC)')
          expect(rows[1]).to include(authorizations.first.origin_project.full_path)
          expect(rows[1]).to include(authorizations.first.last_authorized_at.utc.iso8601)
        end
      end

      context 'when the export fails' do
        let(:export_service) { instance_double(Ci::JobToken::ExportAuthorizationsService) }
        let(:failed_response) { ServiceResponse.error(message: 'Export failed') }

        before do
          allow(::Ci::JobToken::ExportAuthorizationsService).to receive(:new).and_return(export_service)
          allow(export_service).to receive(:execute).and_return(failed_response)
        end

        it 'sets a flash alert and redirects to the project CI/CD settings' do
          get_authorizations

          expect(flash[:alert]).to eq('Failed to generate export')
          expect(response).to redirect_to(project_settings_ci_cd_path(project))
        end
      end
    end
  end

  context 'as a developer' do
    before do
      sign_in(user)
      project.add_developer(user)
      get :show, params: { namespace_id: project.namespace, project_id: project }
    end

    it 'responds with 404' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'as a reporter' do
    before do
      sign_in(user)
      project.add_reporter(user)
      get :show, params: { namespace_id: project.namespace, project_id: project }
    end

    it 'responds with 404' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'as an unauthenticated user' do
    before do
      get :show, params: { namespace_id: project.namespace, project_id: project }
    end

    it 'redirects to sign in' do
      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to('/users/sign_in')
    end
  end
end
