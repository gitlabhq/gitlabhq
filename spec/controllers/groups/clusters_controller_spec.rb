# frozen_string_literal: true

require 'spec_helper'

describe Groups::ClustersController do
  include AccessMatchersForController
  include GoogleApi::CloudPlatformHelpers

  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET new' do
    def go
      get :new, group_id: group
    end

    include_examples 'new cluster action', parent_type: :group

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'POST create_gcp' do
    let(:legacy_abac_param) { 'true' }
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project-12345',
            legacy_abac: legacy_abac_param
          }
        }
      }
    end

    def go
      post :create_gcp, params.merge(group_id: group)
    end

    describe 'functionality' do
      include_examples 'create_gcp action', parent_type: :group
    end

    describe 'security' do
      before do
        allow_any_instance_of(described_class)
        .to receive(:token_in_session).and_return('token')
        allow_any_instance_of(described_class)
        .to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)
        allow_any_instance_of(GoogleApi::CloudPlatform::Client)
          .to receive(:projects_zones_clusters_create) do
          OpenStruct.new(
            self_link: 'projects/gcp-project-12345/zones/us-central1-a/operations/ope-123',
            status: 'RUNNING'
          )
        end

        allow(WaitForClusterCreationWorker).to receive(:perform_in).and_return(nil)
      end

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'POST create_user' do
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          platform_kubernetes_attributes: {
            api_url: 'http://my-url',
            token: 'test',
            namespace: 'aaa'
          }
        }
      }
    end

    def go
      post :create_user, params.merge(group_id: group)
    end

    describe 'functionality' do
      include_examples 'create_user action', parent_type: :group
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end
end
