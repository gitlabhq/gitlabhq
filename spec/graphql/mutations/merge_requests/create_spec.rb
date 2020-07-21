# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::Create do
  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:context) do
    GraphQL::Query::Context.new(
      query: OpenStruct.new(schema: nil),
      values: { current_user: user },
      object: nil
    )
  end

  describe '#resolve' do
    subject do
      mutation.resolve(
        project_path: project.full_path,
        title: title,
        source_branch: source_branch,
        target_branch: target_branch,
        description: description,
        labels: labels
      )
    end

    let(:title) { 'MergeRequest' }
    let(:source_branch) { 'feature' }
    let(:target_branch) { 'master' }
    let(:description) { nil }
    let(:labels) { nil }

    let(:mutated_merge_request) { subject[:merge_request] }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when user does not have enough permissions to create a merge request' do
      before do
        project.add_guest(user)
      end

      it 'raises an error if the resource is not accessible to the user' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user can create a merge request' do
      before_all do
        project.add_developer(user)
      end

      it 'creates a new merge request' do
        expect { mutated_merge_request }.to change(MergeRequest, :count).by(1)
      end

      it 'returns a new merge request' do
        expect(mutated_merge_request.title).to eq(title)
        expect(subject[:errors]).to be_empty
      end

      context 'when optional description field is set' do
        let(:description) { 'content' }

        it 'returns a new merge request with a description' do
          expect(mutated_merge_request.description).to eq(description)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when optional labels field is set' do
        let(:labels) { %w[label-1 label-2] }

        it 'returns a new merge request with labels' do
          expect(mutated_merge_request.labels.map(&:title)).to eq(labels)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when service cannot create a merge request' do
        let(:title) { nil }

        it 'does not create a new merge request' do
          expect { mutated_merge_request }.not_to change(MergeRequest, :count)
        end

        it 'returns errors' do
          expect(mutated_merge_request).to be_nil
          expect(subject[:errors]).to eq(['Title can\'t be blank'])
        end
      end
    end
  end
end
