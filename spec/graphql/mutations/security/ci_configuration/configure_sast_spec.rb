# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Security::CiConfiguration::ConfigureSast do
  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }

  let_it_be(:service_result_json) do
    {
      status: "success",
      success_path: "http://127.0.0.1:3000/root/demo-historic-secrets/-/merge_requests/new?",
      errors: nil
    }
  end

  let_it_be(:service_error_result_json) do
    {
      status: "error",
      success_path: nil,
      errors: %w(error1 error2)
    }
  end

  let(:context) do
    GraphQL::Query::Context.new(
      query: OpenStruct.new(schema: nil),
      values: { current_user: user },
      object: nil
    )
  end

  specify { expect(described_class).to require_graphql_authorizations(:push_code) }

  describe '#resolve' do
    subject { mutation.resolve(project_path: project.full_path, configuration: {}) }

    let(:result) { subject }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when user does not have enough permissions' do
      before do
        project.add_guest(user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is a maintainer of a different project' do
      before do
        create(:project_empty_repo).add_maintainer(user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user does not have permission to create a new branch' do
      before_all do
        project.add_developer(user)
      end

      let(:error_message) { 'You are not allowed to create protected branches on this project.' }

      it 'returns an array of errors' do
        allow_next_instance_of(::Files::MultiService) do |multi_service|
          allow(multi_service).to receive(:execute).and_raise(Gitlab::Git::PreReceiveError.new("GitLab: #{error_message}"))
        end

        expect(result).to match(
          status: :error,
          success_path: nil,
          errors: match_array([error_message])
        )
      end
    end

    context 'when the user can create a merge request' do
      before_all do
        project.add_developer(user)
      end

      context 'when service successfully generates a path to create a new merge request' do
        it 'returns a success path' do
          allow_next_instance_of(::Security::CiConfiguration::SastCreateService) do |service|
            allow(service).to receive(:execute).and_return(service_result_json)
          end

          expect(result).to match(
            status: 'success',
            success_path: service_result_json[:success_path],
            errors: []
          )
        end
      end

      context 'when service can not generate any path to create a new merge request' do
        it 'returns an array of errors' do
          allow_next_instance_of(::Security::CiConfiguration::SastCreateService) do |service|
            allow(service).to receive(:execute).and_return(service_error_result_json)
          end

          expect(result).to match(
            status: 'error',
            success_path: be_nil,
            errors: match_array(service_error_result_json[:errors])
          )
        end
      end
    end
  end
end
