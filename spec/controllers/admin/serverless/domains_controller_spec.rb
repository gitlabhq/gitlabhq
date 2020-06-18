# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Serverless::DomainsController do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe '#index' do
    context 'non-admin user' do
      before do
        sign_in(user)
      end

      it 'responds with 404' do
        get :index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'admin user' do
      before do
        create(:pages_domain)
        sign_in(admin)
      end

      context 'with serverless_domain feature disabled' do
        before do
          stub_feature_flags(serverless_domain: false)
        end

        it 'responds with 404' do
          get :index

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when instance-level serverless domain exists' do
        let!(:serverless_domain) { create(:pages_domain, :instance_serverless) }

        it 'loads the instance serverless domain' do
          get :index

          expect(assigns(:domain).id).to eq(serverless_domain.id)
        end
      end

      context 'when domain does not exist' do
        it 'initializes an instance serverless domain' do
          get :index

          domain = assigns(:domain)

          expect(domain.persisted?).to eq(false)
          expect(domain.wildcard).to eq(true)
          expect(domain.scope).to eq('instance')
          expect(domain.usage).to eq('serverless')
        end
      end
    end
  end

  describe '#create' do
    let(:create_params) do
      sample_domain = build(:pages_domain)

      {
        domain: 'serverless.gitlab.io',
        user_provided_certificate: sample_domain.certificate,
        user_provided_key: sample_domain.key
      }
    end

    context 'non-admin user' do
      before do
        sign_in(user)
      end

      it 'responds with 404' do
        post :create, params: { pages_domain: create_params }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'admin user' do
      before do
        sign_in(admin)
      end

      context 'with serverless_domain feature disabled' do
        before do
          stub_feature_flags(serverless_domain: false)
        end

        it 'responds with 404' do
          post :create, params: { pages_domain: create_params }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when an instance-level serverless domain exists' do
        let!(:serverless_domain) { create(:pages_domain, :instance_serverless) }

        it 'does not create a new domain' do
          expect { post :create, params: { pages_domain: create_params } }.not_to change { PagesDomain.instance_serverless.count }
        end

        it 'redirects to index' do
          post :create, params: { pages_domain: create_params }

          expect(response).to redirect_to admin_serverless_domains_path
          expect(flash[:notice]).to include('An instance-level serverless domain already exists.')
        end
      end

      context 'when an instance-level serverless domain does not exist' do
        it 'creates an instance serverless domain with the provided attributes' do
          expect { post :create, params: { pages_domain: create_params } }.to change { PagesDomain.instance_serverless.count }.by(1)

          domain = PagesDomain.instance_serverless.first
          expect(domain.domain).to eq(create_params[:domain])
          expect(domain.certificate).to eq(create_params[:user_provided_certificate])
          expect(domain.key).to eq(create_params[:user_provided_key])
          expect(domain.wildcard).to eq(true)
          expect(domain.scope).to eq('instance')
          expect(domain.usage).to eq('serverless')
        end

        it 'redirects to index' do
          post :create, params: { pages_domain: create_params }

          expect(response).to redirect_to admin_serverless_domains_path
          expect(flash[:notice]).to include('Domain was successfully created.')
        end
      end

      context 'when there are errors' do
        it 'renders index view' do
          post :create, params: { pages_domain: { foo: 'bar' } }

          expect(assigns(:domain).errors.size).to be > 0
          expect(response).to render_template('index')
        end
      end
    end
  end

  describe '#update' do
    let(:domain) { create(:pages_domain, :instance_serverless) }

    let(:update_params) do
      sample_domain = build(:pages_domain)

      {
        user_provided_certificate: sample_domain.certificate,
        user_provided_key: sample_domain.key
      }
    end

    context 'non-admin user' do
      before do
        sign_in(user)
      end

      it 'responds with 404' do
        put :update, params: { id: domain.id, pages_domain: update_params }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'admin user' do
      before do
        sign_in(admin)
      end

      context 'with serverless_domain feature disabled' do
        before do
          stub_feature_flags(serverless_domain: false)
        end

        it 'responds with 404' do
          put :update, params: { id: domain.id, pages_domain: update_params }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when domain exists' do
        it 'updates the domain with the provided attributes' do
          new_certificate = build(:pages_domain, :ecdsa).certificate
          new_key = build(:pages_domain, :ecdsa).key

          put :update, params: { id: domain.id, pages_domain: { user_provided_certificate: new_certificate, user_provided_key: new_key } }

          domain.reload

          expect(domain.certificate).to eq(new_certificate)
          expect(domain.key).to eq(new_key)
        end

        it 'does not update the domain name' do
          put :update, params: { id: domain.id, pages_domain: { domain: 'new.com' } }

          expect(domain.reload.domain).not_to eq('new.com')
        end

        it 'redirects to index' do
          put :update, params: { id: domain.id, pages_domain: update_params }

          expect(response).to redirect_to admin_serverless_domains_path
          expect(flash[:notice]).to include('Domain was successfully updated.')
        end
      end

      context 'when domain does not exist' do
        it 'returns 404' do
          put :update, params: { id: 0, pages_domain: update_params }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when there are errors' do
        it 'renders index view' do
          put :update, params: { id: domain.id, pages_domain: { user_provided_certificate: 'bad certificate' } }

          expect(assigns(:domain).errors.size).to be > 0
          expect(response).to render_template('index')
        end
      end
    end
  end

  describe '#verify' do
    let(:domain) { create(:pages_domain, :instance_serverless) }

    context 'non-admin user' do
      before do
        sign_in(user)
      end

      it 'responds with 404' do
        post :verify, params: { id: domain.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'admin user' do
      before do
        sign_in(admin)
      end

      def stub_service
        service = double(:service)

        expect(VerifyPagesDomainService).to receive(:new).with(domain).and_return(service)

        service
      end

      context 'with serverless_domain feature disabled' do
        before do
          stub_feature_flags(serverless_domain: false)
        end

        it 'responds with 404' do
          post :verify, params: { id: domain.id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      it 'handles verification success' do
        expect(stub_service).to receive(:execute).and_return(status: :success)

        post :verify, params: { id: domain.id }

        expect(response).to redirect_to admin_serverless_domains_path
        expect(flash[:notice]).to eq('Successfully verified domain ownership')
      end

      it 'handles verification failure' do
        expect(stub_service).to receive(:execute).and_return(status: :failed)

        post :verify, params: { id: domain.id }

        expect(response).to redirect_to admin_serverless_domains_path
        expect(flash[:alert]).to eq('Failed to verify domain ownership')
      end
    end
  end

  describe '#destroy' do
    let!(:domain) { create(:pages_domain, :instance_serverless) }

    context 'non-admin user' do
      before do
        sign_in(user)
      end

      it 'responds with 404' do
        delete :destroy, params: { id: domain.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'admin user' do
      before do
        sign_in(admin)
      end

      context 'with serverless_domain feature disabled' do
        before do
          stub_feature_flags(serverless_domain: false)
        end

        it 'responds with 404' do
          delete :destroy, params: { id: domain.id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when domain exists' do
        context 'and is not associated to any clusters' do
          it 'deletes the domain' do
            expect { delete :destroy, params: { id: domain.id } }
              .to change { PagesDomain.count }.from(1).to(0)

            expect(response).to have_gitlab_http_status(:found)
            expect(flash[:notice]).to include('Domain was successfully deleted.')
          end
        end

        context 'and is associated to any clusters' do
          before do
            create(:serverless_domain_cluster, pages_domain: domain)
          end

          it 'does not delete the domain' do
            expect { delete :destroy, params: { id: domain.id } }
              .not_to change { PagesDomain.count }

            expect(response).to have_gitlab_http_status(:conflict)
            expect(flash[:notice]).to include('Domain cannot be deleted while associated to one or more clusters.')
          end
        end
      end

      context 'when domain does not exist' do
        before do
          domain.destroy!
        end

        it 'responds with 404' do
          delete :destroy, params: { id: domain.id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
