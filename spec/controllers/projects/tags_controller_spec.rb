require 'spec_helper'

describe Projects::TagsController do
  let(:project) { create(:project, :public) }
  let!(:release) { create(:release, project: project) }
  let!(:invalid_release) { create(:release, project: project, tag: 'does-not-exist') }

  describe 'GET index' do
    before { get :index, namespace_id: project.namespace.to_param, project_id: project.to_param }

    it 'returns the tags for the page' do
      expect(assigns(:tags).map(&:name)).to eq(['v1.1.0', 'v1.0.0'])
    end

    it 'returns releases matching those tags' do
      expect(assigns(:releases)).to include(release)
      expect(assigns(:releases)).not_to include(invalid_release)
    end
  end
end
