# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Branches::Create do
  include GraphqlHelpers

  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }

  let(:context) do
    GraphQL::Query::Context.new(
      query: query_double(schema: nil),
      values: { current_user: user },
      object: nil
    )
  end

  describe '#resolve' do
    subject { mutation.resolve(project_path: project.full_path, name: branch, ref: ref) }

    let(:branch) { 'new_branch' }
    let(:ref) { 'master' }
    let(:mutated_branch) { subject[:branch] }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can create a branch' do
      before do
        project.add_developer(user)

        allow_next_instance_of(::Branches::CreateService, project, user) do |create_service|
          allow(create_service).to receive(:execute).with(branch, ref) { service_result }
        end
      end

      context 'when service successfully creates a new branch' do
        let(:service_result) { { status: :success, branch: double(name: branch) } }

        it 'returns a new branch' do
          expect(mutated_branch.name).to eq(branch)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when service fails to create a new branch' do
        let(:service_result) { { status: :error, message: 'Branch already exists' } }

        it { expect(mutated_branch).to be_nil }
        it { expect(subject[:errors]).to eq(['Branch already exists']) }
      end
    end
  end
end
