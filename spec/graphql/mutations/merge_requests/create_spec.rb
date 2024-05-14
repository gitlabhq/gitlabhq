# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::Create do
  include GraphqlHelpers

  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  let(:user) { create(:user) }

  let(:context) do
    GraphQL::Query::Context.new(
      query: query_double(schema: nil),
      values: { current_user: user }
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

    shared_examples 'resource not available' do
      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is not a project member' do
      let_it_be(:project) { create(:project, :public, :repository) }

      it_behaves_like 'resource not available'
    end

    context 'when user is a direct project member' do
      let_it_be(:project) { create(:project, :public, :repository) }

      context 'and user is a guest' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'resource not available'
      end

      context 'and user is a developer' do
        before do
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
            expect(subject[:errors]).to match_array(['Title can\'t be blank'])
          end
        end
      end
    end

    context 'when user is an inherited member from the group' do
      let_it_be(:group) { create(:group, :public) }

      context 'when project is public with private merge requests' do
        let_it_be(:project) do
          create(
            :project,
            :public,
            :repository,
            group: group,
            merge_requests_access_level: ProjectFeature::DISABLED
          )
        end

        context 'and user is a guest' do
          before do
            group.add_guest(user)
          end

          it_behaves_like 'resource not available'
        end
      end

      context 'when project is private' do
        let_it_be(:project) { create(:project, :private, :repository, group: group) }

        context 'and user is a guest' do
          before do
            group.add_guest(user)
          end

          it_behaves_like 'resource not available'
        end
      end
    end
  end
end
