# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::WebIdeTerminalsController do
  let_it_be(:owner) { create(:owner) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:project) do
    create(:project, :private, :repository, namespace: owner.namespace).tap do |project|
      project.add_maintainer(maintainer)
      project.add_developer(developer)
      project.add_reporter(reporter)
      project.add_guest(guest)
    end
  end

  let(:pipeline) { create(:ci_pipeline, project: project, source: :webide, config_source: :webide_source, user: user) }
  let(:job) { create(:ci_build, pipeline: pipeline, user: user, project: project) }
  let(:user) { maintainer }

  before do
    sign_in(user)
  end

  shared_examples 'terminal access rights' do
    context 'with admin' do
      let(:user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns 200' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when admin mode is disabled' do
        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with owner' do
      let(:user) { owner }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with maintainer' do
      let(:user) { maintainer }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with developer' do
      let(:user) { developer }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with guest' do
      let(:user) { guest }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with non member' do
      let(:user) { create(:user) }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'when pipeline is not from a webide source' do
    context 'with admin' do
      let(:user) { admin }
      let(:pipeline) { create(:ci_pipeline, project: project, source: :chat, user: user) }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET show' do
    before do
      get(:show, params: { namespace_id: project.namespace.to_param, project_id: project, id: job.id })
    end

    it_behaves_like 'terminal access rights'
    it_behaves_like 'when pipeline is not from a webide source'
  end

  describe 'POST check_config' do
    let(:result) { { status: :success } }

    before do
      allow_next_instance_of(::Ide::TerminalConfigService) do |instance|
        allow(instance).to receive(:execute).and_return(result)
      end

      post :check_config, params: {
                            namespace_id: project.namespace.to_param,
                            project_id: project.to_param,
                            branch: 'master'
                          }
    end

    it_behaves_like 'terminal access rights'

    context 'when invalid config file' do
      let(:user) { admin }
      let(:result) { { status: :error } }

      it 'returns 422', :enable_admin_mode do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST create' do
    let(:branch) { 'master' }

    subject do
      post :create, params: {
                      namespace_id: project.namespace.to_param,
                      project_id: project.to_param,
                      branch: branch
                    }
    end

    context 'when terminal job is created successfully' do
      let(:build) { create(:ci_build, project: project) }
      let(:pipeline) { build.pipeline }

      before do
        allow_next_instance_of(::Ci::CreateWebIdeTerminalService) do |instance|
          allow(instance).to receive(:execute).and_return(status: :success, pipeline: pipeline)
        end
      end

      context 'access rights' do
        it_behaves_like 'terminal access rights' do
          before do
            subject
          end
        end
      end
    end

    context 'when branch does not exist' do
      let(:user) { admin }
      let(:branch) { 'foobar' }

      it 'returns 400', :enable_admin_mode do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when there is an error creating the job' do
      let(:user) { admin }

      before do
        allow_next_instance_of(::Ci::CreateWebIdeTerminalService) do |instance|
          allow(instance).to receive(:execute).and_return(status: :error, message: 'foobar')
        end
      end

      it 'returns 400', :enable_admin_mode do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when the current build is nil' do
      let(:user) { admin }

      before do
        allow(pipeline).to receive(:builds).and_return([])
        allow_next_instance_of(::Ci::CreateWebIdeTerminalService) do |instance|
          allow(instance).to receive(:execute).and_return(status: :success, pipeline: pipeline)
        end
      end

      it 'returns 400', :enable_admin_mode do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'POST cancel' do
    let(:job) { create(:ci_build, :running, pipeline: pipeline, user: user, project: project) }

    before do
      post(:cancel, params: {
                      namespace_id: project.namespace.to_param,
                      project_id: project.to_param,
                      id: job.id
                    })
    end

    it_behaves_like 'terminal access rights'
    it_behaves_like 'when pipeline is not from a webide source'

    context 'when job is not cancelable' do
      let!(:job) { create(:ci_build, :failed, pipeline: pipeline, user: user) }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST retry' do
    let(:status) { :failed }
    let(:job) { create(:ci_build, status, pipeline: pipeline, user: user, project: project) }

    before do
      post(:retry, params: {
                     namespace_id: project.namespace.to_param,
                     project_id: project.to_param,
                     id: job.id
                   })
    end

    it_behaves_like 'terminal access rights'
    it_behaves_like 'when pipeline is not from a webide source'

    context 'when job is not retryable' do
      let(:status) { :running }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when job is cancelled' do
      let(:status) { :canceled }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when job fails' do
      let(:status) { :failed }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when job is successful' do
      let(:status) { :success }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
