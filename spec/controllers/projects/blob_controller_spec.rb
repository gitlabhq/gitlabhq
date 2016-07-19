require 'rails_helper'

describe Projects::BlobController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    user = create(:user)
    project.team << [user, :master]

    sign_in(user)
  end

  describe 'GET diff' do
    render_views

    def do_get(opts = {})
      params = { namespace_id: project.namespace.to_param,
                 project_id: project.to_param,
                 id: 'master/CHANGELOG' }
      get :diff, params.merge(opts)
    end

    context 'when essential params are missing' do
      it 'renders nothing' do
        do_get

        expect(response.body).to be_blank
      end
    end

    context 'when essential params are present' do
      it 'renders the diff content' do
        do_get(since: 1, to: 5, offset: 10)

        expect(response.body).to be_present
      end
    end
  end
end
