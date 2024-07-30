# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Clusters::Agents::Delete do
  include GraphqlHelpers

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  let(:cluster_agent) { create(:cluster_agent) }
  let(:project) { cluster_agent.project }
  let(:current_user) { create(:user) }

  specify { expect(described_class).to require_graphql_authorizations(:admin_cluster) }

  describe '#resolve' do
    subject { mutation.resolve(id: cluster_agent.to_global_id) }

    context 'without user permissions' do
      it 'fails to delete the cluster agent', :aggregate_failures do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        expect { cluster_agent.reload }.not_to raise_error
      end
    end

    context 'with user permissions' do
      before do
        project.add_maintainer(current_user)
      end

      it 'deletes a cluster agent', :aggregate_failures do
        expect { subject }.to change { ::Clusters::Agent.count }.by(-1)
        expect { cluster_agent.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
