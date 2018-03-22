require 'spec_helper'

describe Projects::PipelineSchedulesController do
  include AccessMatchersForController

  set(:project) { create(:project, :public, :repository) }
  set(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }

  describe 'GET #index' do
    render_views

    let(:scope) { nil }
    let!(:inactive_pipeline_schedule) do
      create(:ci_pipeline_schedule, :inactive, project: project)
    end

    it 'renders the index view' do
      visit_pipelines_schedules

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end

    it 'avoids N + 1 queries' do
      control_count = ActiveRecord::QueryRecorder.new { visit_pipelines_schedules }.count

      create_list(:ci_pipeline_schedule, 2, project: project)

      expect { visit_pipelines_schedules }.not_to exceed_query_limit(control_count)
    end

    context 'when the scope is set to active' do
      let(:scope) { 'active' }

      before do
        visit_pipelines_schedules
      end

      it 'only shows active pipeline schedules' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:schedules)).to include(pipeline_schedule)
        expect(assigns(:schedules)).not_to include(inactive_pipeline_schedule)
      end
    end

    def visit_pipelines_schedules
      get :index, namespace_id: project.namespace.to_param, project_id: project, scope: scope
    end
  end

  describe 'GET #new' do
    set(:user) { create(:user) }

    before do
      project.add_developer(user)
      sign_in(user)
    end

    it 'initializes a pipeline schedule model' do
      get :new, namespace_id: project.namespace.to_param, project_id: project

      expect(response).to have_gitlab_http_status(:ok)
      expect(assigns(:schedule)).to be_a_new(Ci::PipelineSchedule)
    end
  end

  describe 'POST #create' do
    describe 'functionality' do
      set(:user) { create(:user) }

      before do
        project.add_developer(user)
        sign_in(user)
      end

      let(:basic_param) do
        attributes_for(:ci_pipeline_schedule)
      end

      context 'when variables_attributes has one variable' do
        let(:schedule) do
          basic_param.merge({
            variables_attributes: [{ key: 'AAA', secret_value: 'AAA123' }]
          })
        end

        it 'creates a new schedule' do
          expect { go }
            .to change { Ci::PipelineSchedule.count }.by(1)
            .and change { Ci::PipelineScheduleVariable.count }.by(1)

          expect(response).to have_gitlab_http_status(:found)

          Ci::PipelineScheduleVariable.last.tap do |v|
            expect(v.key).to eq("AAA")
            expect(v.value).to eq("AAA123")
          end
        end
      end

      context 'when variables_attributes has two variables and duplicated' do
        let(:schedule) do
          basic_param.merge({
            variables_attributes: [{ key: 'AAA', secret_value: 'AAA123' },
                                   { key: 'AAA', secret_value: 'BBB123' }]
          })
        end

        it 'returns an error that the keys of variable are duplicated' do
          expect { go }
            .to change { Ci::PipelineSchedule.count }.by(0)
            .and change { Ci::PipelineScheduleVariable.count }.by(0)

          expect(assigns(:schedule).errors['variables']).not_to be_empty
        end
      end
    end

    describe 'security' do
      let(:schedule) { attributes_for(:ci_pipeline_schedule) }

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
      it { expect { go }.to be_allowed_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
      it { expect { go }.to be_denied_for(:visitor) }
    end

    def go
      post :create, namespace_id: project.namespace.to_param, project_id: project, schedule: schedule
    end
  end

  describe 'PUT #update' do
    describe 'functionality' do
      set(:user) { create(:user) }
      let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }

      before do
        project.add_developer(user)
        sign_in(user)
      end

      context 'when a pipeline schedule has no variables' do
        let(:basic_param) do
          { description: 'updated_desc', cron: '0 1 * * *', cron_timezone: 'UTC', ref: 'patch-x', active: true }
        end

        context 'when params include one variable' do
          let(:schedule) do
            basic_param.merge({
              variables_attributes: [{ key: 'AAA', secret_value: 'AAA123' }]
            })
          end

          it 'inserts new variable to the pipeline schedule' do
            expect { go }.to change { Ci::PipelineScheduleVariable.count }.by(1)

            pipeline_schedule.reload
            expect(response).to have_gitlab_http_status(:found)
            expect(pipeline_schedule.variables.last.key).to eq('AAA')
            expect(pipeline_schedule.variables.last.value).to eq('AAA123')
          end
        end

        context 'when params include two duplicated variables' do
          let(:schedule) do
            basic_param.merge({
              variables_attributes: [{ key: 'AAA', secret_value: 'AAA123' },
                                     { key: 'AAA', secret_value: 'BBB123' }]
            })
          end

          it 'returns an error that variables are duplciated' do
            go

            expect(assigns(:schedule).errors['variables']).not_to be_empty
          end
        end
      end

      context 'when a pipeline schedule has one variable' do
        let(:basic_param) do
          { description: 'updated_desc', cron: '0 1 * * *', cron_timezone: 'UTC', ref: 'patch-x', active: true }
        end

        let!(:pipeline_schedule_variable) do
          create(:ci_pipeline_schedule_variable,
            key: 'CCC', pipeline_schedule: pipeline_schedule)
        end

        context 'when adds a new variable' do
          let(:schedule) do
            basic_param.merge({
              variables_attributes: [{ key: 'AAA', secret_value: 'AAA123' }]
            })
          end

          it 'adds the new variable' do
            expect { go }.to change { Ci::PipelineScheduleVariable.count }.by(1)

            pipeline_schedule.reload
            expect(pipeline_schedule.variables.last.key).to eq('AAA')
          end
        end

        context 'when adds a new duplicated variable' do
          let(:schedule) do
            basic_param.merge({
              variables_attributes: [{ key: 'CCC', secret_value: 'AAA123' }]
            })
          end

          it 'returns an error' do
            expect { go }.not_to change { Ci::PipelineScheduleVariable.count }

            pipeline_schedule.reload
            expect(assigns(:schedule).errors['variables']).not_to be_empty
          end
        end

        context 'when updates a variable' do
          let(:schedule) do
            basic_param.merge({
              variables_attributes: [{ id: pipeline_schedule_variable.id, secret_value: 'new_value' }]
            })
          end

          it 'updates the variable' do
            expect { go }.not_to change { Ci::PipelineScheduleVariable.count }

            pipeline_schedule_variable.reload
            expect(pipeline_schedule_variable.value).to eq('new_value')
          end
        end

        context 'when deletes a variable' do
          let(:schedule) do
            basic_param.merge({
              variables_attributes: [{ id: pipeline_schedule_variable.id, _destroy: true }]
            })
          end

          it 'delete the existsed variable' do
            expect { go }.to change { Ci::PipelineScheduleVariable.count }.by(-1)
          end
        end

        context 'when deletes and creates a same key simultaneously' do
          let(:schedule) do
            basic_param.merge({
              variables_attributes: [{ id: pipeline_schedule_variable.id, _destroy: true },
                                     { key: 'CCC', secret_value: 'CCC123' }]
            })
          end

          it 'updates the variable' do
            expect { go }.not_to change { Ci::PipelineScheduleVariable.count }

            pipeline_schedule.reload
            expect(pipeline_schedule.variables.last.key).to eq('CCC')
            expect(pipeline_schedule.variables.last.value).to eq('CCC123')
          end
        end
      end
    end

    describe 'security' do
      let(:schedule) { { description: 'updated_desc' } }

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
      it { expect { go }.to be_allowed_for(:developer).of(project).own(pipeline_schedule) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
      it { expect { go }.to be_denied_for(:visitor) }

      context 'when a developer created a pipeline schedule' do
        let(:developer_1) { create(:user) }
        let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: developer_1) }

        before do
          project.add_developer(developer_1)
        end

        it { expect { go }.to be_allowed_for(developer_1) }
        it { expect { go }.to be_denied_for(:developer).of(project) }
        it { expect { go }.to be_allowed_for(:master).of(project) }
      end

      context 'when a master created a pipeline schedule' do
        let(:master_1) { create(:user) }
        let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: master_1) }

        before do
          project.add_master(master_1)
        end

        it { expect { go }.to be_allowed_for(master_1) }
        it { expect { go }.to be_allowed_for(:master).of(project) }
        it { expect { go }.to be_denied_for(:developer).of(project) }
      end
    end

    def go
      put :update, namespace_id: project.namespace.to_param,
                   project_id: project, id: pipeline_schedule,
                   schedule: schedule
    end
  end

  describe 'GET #edit' do
    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      it 'loads the pipeline schedule' do
        get :edit, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:schedule)).to eq(pipeline_schedule)
      end
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
      it { expect { go }.to be_allowed_for(:developer).of(project).own(pipeline_schedule) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
      it { expect { go }.to be_denied_for(:visitor) }
    end

    def go
      get :edit, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id
    end
  end

  describe 'GET #take_ownership' do
    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
      it { expect { go }.to be_allowed_for(:developer).of(project).own(pipeline_schedule) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
      it { expect { go }.to be_denied_for(:visitor) }
    end

    def go
      post :take_ownership, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id
    end
  end

  describe 'POST #play', :clean_gitlab_redis_cache do
    set(:user) { create(:user) }
    let(:ref) { 'master' }

    before do
      project.add_developer(user)

      sign_in(user)
    end

    context 'when an anonymous user makes the request' do
      before do
        sign_out(user)
      end

      it 'does not allow pipeline to be executed' do
        expect(RunPipelineScheduleWorker).not_to receive(:perform_async)

        post :play, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when a developer makes the request' do
      it 'executes a new pipeline' do
        expect(RunPipelineScheduleWorker).to receive(:perform_async).with(pipeline_schedule.id, user.id).and_return('job-123')

        post :play, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id

        expect(flash[:notice]).to start_with 'Successfully scheduled a pipeline to run'
        expect(response).to have_gitlab_http_status(302)
      end

      it 'prevents users from scheduling the same pipeline repeatedly' do
        2.times do
          post :play, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id
        end

        expect(flash.to_a.size).to eq(2)
        expect(flash[:alert]).to eq 'You cannot play this scheduled pipeline at the moment. Please wait a minute.'
        expect(response).to have_gitlab_http_status(302)
      end
    end

    context 'when a developer attempts to schedule a protected ref' do
      it 'does not allow pipeline to be executed' do
        create(:protected_branch, project: project, name: ref)
        protected_schedule = create(:ci_pipeline_schedule, project: project, ref: ref)

        expect(RunPipelineScheduleWorker).not_to receive(:perform_async)

        post :play, namespace_id: project.namespace.to_param, project_id: project, id: protected_schedule.id

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'DELETE #destroy' do
    set(:user) { create(:user) }

    context 'when a developer makes the request' do
      before do
        project.add_developer(user)
        sign_in(user)

        delete :destroy, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id
      end

      it 'does not delete the pipeline schedule' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when a master makes the request' do
      before do
        project.add_master(user)
        sign_in(user)
      end

      it 'destroys the pipeline schedule' do
        expect do
          delete :destroy, namespace_id: project.namespace.to_param, project_id: project, id: pipeline_schedule.id
        end.to change { project.pipeline_schedules.count }.by(-1)

        expect(response).to have_gitlab_http_status(302)
      end
    end
  end
end
