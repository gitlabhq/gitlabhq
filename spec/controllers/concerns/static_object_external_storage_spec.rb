# frozen_string_literal: true

require 'spec_helper'

describe StaticObjectExternalStorage do
  controller(Projects::ApplicationController) do
    include StaticObjectExternalStorage

    before_action :redirect_to_external_storage, if: :static_objects_external_storage_enabled?

    def show
      head :ok
    end
  end

  let(:project) { create(:project, :public) }
  let(:user) { create(:user, static_object_token: 'hunter1') }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context 'when external storage is not configured' do
    it 'calls the action normally' do
      expect(Gitlab::CurrentSettings.static_objects_external_storage_url).to be_blank

      do_request

      expect(response).to have_gitlab_http_status(200)
    end
  end

  context 'when external storage is configured' do
    before do
      allow_any_instance_of(ApplicationSetting).to receive(:static_objects_external_storage_url).and_return('https://cdn.gitlab.com')
      allow_any_instance_of(ApplicationSetting).to receive(:static_objects_external_storage_auth_token).and_return('letmein')

      routes.draw { get '/:namespace_id/:id' => 'projects/application#show' }
    end

    context 'when external storage token is empty' do
      let(:base_redirect_url) { "https://cdn.gitlab.com/#{project.namespace.to_param}/#{project.to_param}" }

      context 'when project is public' do
        it 'redirects to external storage URL without adding a token parameter' do
          do_request

          expect(response).to redirect_to(base_redirect_url)
        end
      end

      context 'when project is not public' do
        let(:project) { create(:project, :private) }

        it 'redirects to external storage URL a token parameter added' do
          do_request

          expect(response).to redirect_to("#{base_redirect_url}?token=#{user.static_object_token}")
        end

        context 'when path includes extra parameters' do
          it 'includes the parameters in the redirect URL' do
            do_request(foo: 'bar')

            expect(response.location).to eq("#{base_redirect_url}?foo=bar&token=#{user.static_object_token}")
          end
        end
      end
    end

    context 'when external storage token is present' do
      context 'when token is correct' do
        it 'calls the action normally' do
          request.headers['X-Gitlab-External-Storage-Token'] = 'letmein'
          do_request

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when token is incorrect' do
        it 'return 403' do
          request.headers['X-Gitlab-External-Storage-Token'] = 'donotletmein'
          do_request

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end
  end

  def do_request(extra_params = {})
    get :show, params: { namespace_id: project.namespace, id: project }.merge(extra_params)
  end
end
