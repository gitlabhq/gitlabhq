# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Clusters::Agents::Create do
  include GraphqlHelpers

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  let(:project) { create(:project, :public, :repository) }
  let(:current_user) { create(:user) }

  specify { expect(described_class).to require_graphql_authorizations(:create_cluster) }

  describe '#resolve' do
    subject { mutation.resolve(project_path: project.full_path, name: 'test-agent') }

    context 'without project permissions' do
      it 'raises an error if the resource is not accessible to the user' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with user permissions' do
      before do
        project.add_maintainer(current_user)
      end

      it 'creates a new clusters_agent', :aggregate_failures do
        expect { subject }.to change { ::Clusters::Agent.count }.by(1)
        expect(subject[:cluster_agent].name).to eq('test-agent')
        expect(subject[:errors]).to eq([])
      end

      context 'invalid params' do
        subject { mutation.resolve(project_path: project.full_path, name: '@bad_name!') }

        it 'generates an error message when name is invalid', :aggregate_failures do
          expect(subject[:clusters_agent]).to be_nil
          expect(subject[:errors]).to eq(["Name can contain only lowercase letters, digits, and '-', but cannot start or end with '-'"])
        end
      end
    end
  end
end
