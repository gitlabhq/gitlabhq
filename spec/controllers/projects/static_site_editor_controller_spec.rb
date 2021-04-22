# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::StaticSiteEditorController do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }

  let(:data) { { key: 'value' } }

  describe 'GET index' do
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project
      }
    end

    it 'responds with 404 page' do
      get :index, params: default_params

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET show' do
    render_views

    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: 'master/README.md',
        return_url: 'http://example.com'
      }
    end

    let(:service_response) do
      ServiceResponse.success(payload: data)
    end

    before do
      allow_next_instance_of(::StaticSiteEditor::ConfigService) do |instance|
        allow(instance).to receive(:execute).and_return(service_response)
      end
    end

    context 'User roles' do
      context 'anonymous' do
        before do
          get :show, params: default_params
        end

        it 'redirects to sign in and returns' do
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context 'as guest' do
        before do
          project.add_guest(user)
          sign_in(user)
          get :show, params: default_params
        end

        it 'responds with 404 page' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "as developer" do
        before do
          allow(Gitlab::UsageDataCounters::StaticSiteEditorCounter).to receive(:increment_views_count)
          project.add_role(user, 'developer')
          sign_in(user)
          get :show, params: default_params
        end

        it 'increases the views counter' do
          expect(Gitlab::UsageDataCounters::StaticSiteEditorCounter).to have_received(:increment_views_count)
        end

        it 'renders the edit page' do
          expect(response).to render_template(:show)
        end

        it 'assigns ref and path variables' do
          expect(assigns(:ref)).to eq('master')
          expect(assigns(:path)).to eq('README.md')
        end

        context 'when combination of ref and path is incorrect' do
          let(:default_params) { super().merge(id: 'unknown') }

          it 'responds with 404 page' do
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when invalid config file' do
          let(:service_response) { ServiceResponse.error(message: 'invalid') }

          it 'redirects to project page and flashes error message' do
            expect(response).to redirect_to(project_path(project))
            expect(controller).to set_flash[:alert].to('invalid')
          end
        end

        context 'with a service response payload containing multiple data types' do
          let(:data) do
            {
              a_string: 'string',
              an_array: [
                {
                  foo: 'bar'
                }
              ],
              an_integer: 123,
              a_hash: {
                a_deeper_hash: {
                  foo: 'bar'
                }
              },
              a_boolean: true,
              a_nil: nil
            }
          end

          let(:assigns_data) { assigns(:data) }

          it 'leaves data values which are strings as strings' do
            expect(assigns_data[:a_string]).to eq('string')
          end

          it 'leaves data values which are integers as integers' do
            expect(assigns_data[:an_integer]).to eq(123)
          end

          it 'serializes data values which are booleans to JSON' do
            expect(assigns_data[:a_boolean]).to eq('true')
          end

          it 'serializes data values which are arrays to JSON' do
            expect(assigns_data[:an_array]).to eq('[{"foo":"bar"}]')
          end

          it 'serializes data values which are hashes to JSON' do
            expect(assigns_data[:a_hash]).to eq('{"a_deeper_hash":{"foo":"bar"}}')
          end

          it 'serializes data values which are nil to an empty string' do
            expect(assigns_data[:a_nil]).to eq('')
          end
        end
      end
    end
  end
end
