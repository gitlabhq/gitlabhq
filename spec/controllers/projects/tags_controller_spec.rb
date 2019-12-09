# frozen_string_literal: true

require 'spec_helper'

describe Projects::TagsController do
  let(:project) { create(:project, :public, :repository) }
  let!(:release) { create(:release, project: project) }
  let!(:invalid_release) { create(:release, project: project, tag: 'does-not-exist') }

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

    it_behaves_like 'authenticates sessionless user', :index, :atom do
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
end
