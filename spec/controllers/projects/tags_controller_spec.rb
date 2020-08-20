# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TagsController do
  let(:project) { create(:project, :public, :repository) }
  let!(:release) { create(:release, project: project) }
  let!(:invalid_release) { create(:release, project: project, tag: 'does-not-exist') }
  let(:user) { create(:user) }

  describe 'GET index' do
    before do
      get :index, params: { namespace_id: project.namespace.to_param, project_id: project }
    end

    it 'returns the tags for the page' do
      expect(assigns(:tags).map(&:name)).to include('v1.1.0', 'v1.0.0')
    end

    it 'returns releases matching those tags' do
      expect(assigns(:releases)).to include(release)
      expect(assigns(:releases)).not_to include(invalid_release)
    end
  end

  describe 'GET show' do
    before do
      get :show, params: { namespace_id: project.namespace.to_param, project_id: project, id: id }
    end

    context "valid tag" do
      let(:id) { 'v1.0.0' }

      it { is_expected.to respond_with(:success) }
    end

    context "invalid tag" do
      let(:id) { 'latest' }

      it { is_expected.to respond_with(:not_found) }
    end
  end

  context 'private project with token authentication' do
    let(:private_project) { create(:project, :repository, :private) }

    it_behaves_like 'authenticates sessionless user', :index, :atom, ignore_incrementing: true do
      before do
        default_params.merge!(project_id: private_project, namespace_id: private_project.namespace)

        private_project.add_maintainer(user)
      end
    end
  end

  context 'public project with token authentication' do
    let(:public_project) { create(:project, :repository, :public) }

    it_behaves_like 'authenticates sessionless user', :index, :atom, public: true do
      before do
        default_params.merge!(project_id: public_project, namespace_id: public_project.namespace)
      end
    end
  end

  describe 'POST #create' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    let(:release_description) { nil }
    let(:request) do
      post(:create, params: {
             namespace_id: project.namespace.to_param,
             project_id: project,
             tag_name: '1.0',
             ref: 'master',
             release_description: release_description
           })
    end

    it 'creates tag' do
      request

      expect(response).to have_gitlab_http_status(:found)
      expect(project.repository.find_tag('1.0')).to be_present
    end

    # TODO: remove this with the release creation moved to it's own form https://gitlab.com/gitlab-org/gitlab/-/issues/214245
    context 'when release description is set' do
      let(:release_description) { 'some release description' }

      it 'creates tag and release' do
        request

        expect(response).to have_gitlab_http_status(:found)
        expect(project.repository.find_tag('1.0')).to be_present

        release = project.releases.find_by_tag!('1.0')

        expect(release).to be_present
        expect(release.description).to eq(release_description)
      end

      it 'passes the last pipeline for evidence creation', :sidekiq_inline do
        sha = project.repository.commit('master').sha
        create(:ci_empty_pipeline, sha: sha, project: project) # old pipeline
        pipeline = create(:ci_empty_pipeline, sha: sha, project: project)

        # simulating pipeline creation by new tag
        expect_any_instance_of(Repository).to receive(:add_tag).and_wrap_original do |m, *args|
          create(:ci_empty_pipeline, sha: sha, project: project)
          m.call(*args)
        end

        expect_next_instance_of(Releases::CreateEvidenceService, anything, pipeline: pipeline) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        request

        aggregate_failures do
          expect(response).to have_gitlab_http_status(:found)

          release = project.releases.find_by_tag('1.0')

          expect(release).to be_present
          expect(release&.description).to eq(release_description)
        end
      end
    end
  end
end
