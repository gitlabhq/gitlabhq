# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ClusterAgentsHelper, feature_category: :deployment_management do
  describe '#js_cluster_agent_details_data' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { create(:user) }

    let(:user_can_admin_vulerability) { true }
    let(:user_can_admin_cluster) { false }
    let(:agent_name) { 'agent-name' }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(helper)
        .to receive(:can?)
        .with(current_user, :admin_vulnerability, project)
        .and_return(user_can_admin_vulerability)
      allow(helper)
        .to receive(:can?)
        .with(current_user, :admin_cluster, project)
        .and_return(user_can_admin_cluster)
    end

    subject { helper.js_cluster_agent_details_data(agent_name, project) }

    it do
      is_expected.to match({
        agent_name: agent_name,
        project_path: project.full_path,
        activity_empty_state_image: kind_of(String),
        empty_state_svg_path: kind_of(String),
        can_admin_vulnerability: "true",
        kas_address: Gitlab::Kas.external_url,
        kas_install_version: Gitlab::Kas.install_version_info,
        can_admin_cluster: "false"
      })
    end

    context 'user has admin cluster permissions' do
      let(:user_can_admin_cluster) { true }

      it 'displays that the user can admin cluster' do
        expect(subject[:can_admin_cluster]).to eq("true")
      end
    end
  end
end
