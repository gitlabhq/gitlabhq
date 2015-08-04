require 'spec_helper'

describe Projects::RefsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)
    project.team << [user, :developer]
  end

  describe 'GET #logs_tree' do
    def default_get(format = :html)
      get :logs_tree,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: 'master',
          path: 'foo/bar/baz.html',
          format: format
    end

    def xhr_get(format = :html)
      xhr :get,
          :logs_tree,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param, id: 'master',
          path: 'foo/bar/baz.html', format: format
    end

    it 'never throws MissingTemplate' do
      expect { default_get }.not_to raise_error
      expect { xhr_get }.not_to raise_error
    end

    it 'renders 404 for non-JS requests' do
      xhr_get

      expect(response).to be_not_found
    end

    it 'renders JS' do
      xhr_get(:js)
      expect(response).to be_success
    end
  end
end
