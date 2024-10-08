# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Commits::Create do
  include GraphqlHelpers

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:group) { create(:group, :public) }

  specify { expect(described_class).to require_graphql_authorizations(:push_code) }

  describe '#resolve' do
    subject { mutation.resolve(project_path: project.full_path, branch: branch, start_branch: start_branch, message: message, actions: actions) }

    let(:branch) { 'master' }
    let(:start_branch) { nil }
    let(:message) { 'Commit message' }
    let(:file_path) { "#{SecureRandom.uuid}.md" }
    let(:actions) do
      [
        {
          action: 'create',
          file_path: file_path,
          content: 'Hello'
        }
      ]
    end

    let(:mutated_commit) { subject[:commit] }

    context 'when user is not a project member' do
      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is a direct project member' do
      context 'and user is a guest' do
        before do
          project.add_guest(current_user)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'and user is a developer' do
        let(:deltas) { mutated_commit.raw_deltas }

        before_all do
          project.add_developer(current_user)
        end

        context 'when service successfully creates a new commit' do
          it "returns the ETag path for the commit's pipeline" do
            commit_pipeline_path = subject[:commit_pipeline_path]
            expect(commit_pipeline_path).to match(%r{pipelines/sha/\w+})
          end

          it 'returns the content of the commit' do
            expect(subject[:content]).to eq(actions.pluck(:content))
          end

          it 'returns a new commit' do
            expect(mutated_commit).to have_attributes(message: message, project: project)
            expect(subject[:errors]).to be_empty

            expect_to_contain_deltas([
              a_hash_including(a_mode: '0', b_mode: '100644', new_file: true, new_path: file_path)
            ])
          end
        end

        context 'when request has multiple actions' do
          let(:actions) do
            [
              {
                action: 'create',
                file_path: 'foo/foobar',
                content: 'some content'
              },
              {
                action: 'delete',
                file_path: 'README.md'
              },
              {
                action: 'move',
                file_path: "LICENSE.md",
                previous_path: "LICENSE",
                content: "some content"
              },
              {
                action: 'update',
                file_path: 'VERSION',
                content: 'new content'
              },
              {
                action: 'chmod',
                file_path: 'CHANGELOG',
                execute_filemode: true
              }
            ]
          end

          it 'returns a new commit' do
            expect(mutated_commit).to have_attributes(message: message, project: project)
            expect(subject[:errors]).to be_empty

            expect_to_contain_deltas([
              a_hash_including(a_mode: '0', b_mode: '100644', new_path: 'foo/foobar'),
                                       a_hash_including(deleted_file: true, new_path: 'README.md'),
                                       a_hash_including(deleted_file: true, new_path: 'LICENSE'),
                                       a_hash_including(new_file: true, new_path: 'LICENSE.md'),
                                       a_hash_including(new_file: false, new_path: 'VERSION'),
                                       a_hash_including(a_mode: '100644', b_mode: '100755', new_path: 'CHANGELOG')
            ])
          end
        end

        context 'when actions are not defined' do
          let(:actions) { [] }

          it 'returns a new commit' do
            expect(mutated_commit).to have_attributes(message: message, project: project)
            expect(subject[:errors]).to be_empty

            expect_to_contain_deltas([])
          end
        end

        context 'when branch does not exist' do
          let(:branch) { 'unknown' }

          it 'returns errors' do
            expect(mutated_commit).to be_nil
            expect(subject[:errors]).to match_array(['You can only create or edit files when you are on a branch'])
          end
        end

        context 'when branch does not exist and a start branch is provided' do
          let(:branch) { 'my-branch' }
          let(:start_branch) { 'master' }
          let(:actions) do
            [
              {
                action: 'create',
                file_path: 'ANOTHER_FILE.md',
                content: 'Bye'
              }
            ]
          end

          it 'returns a new commit' do
            expect(mutated_commit).to have_attributes(message: message, project: project)
            expect(subject[:errors]).to be_empty
            expect(subject[:content]).to eq(actions.pluck(:content))

            expect_to_contain_deltas([
              a_hash_including(a_mode: '0', b_mode: '100644', new_file: true, new_path: 'ANOTHER_FILE.md')
            ])
          end
        end

        context 'when message is not set' do
          let(:message) { nil }

          it 'returns errors' do
            expect(mutated_commit).to be_nil
            expect(subject[:errors].to_s).to match(/empty CommitMessage/)
          end
        end

        context 'when actions are incorrect' do
          let(:actions) { [{ action: 'unknown', file_path: 'test.md', content: '' }] }

          it 'returns errors' do
            expect(mutated_commit).to be_nil
            expect(subject[:errors]).to match_array(['Unknown action \'unknown\''])
          end
        end

        context 'when branch is protected' do
          before do
            create(:protected_branch, project: project, name: branch)
          end

          it 'returns errors' do
            expect(mutated_commit).to be_nil
            expect(subject[:errors]).to match_array(['You are not allowed to push into this branch'])
          end
        end
      end
    end

    context 'when user is an inherited member from the group' do
      context 'when project is public with private repository' do
        let(:project) { create(:project, :public, :repository, :repository_private, group: group) }

        context 'and user is a guest' do
          before do
            group.add_guest(current_user)
          end

          it 'raises an error' do
            expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end

      context 'when project is private' do
        let(:project) { create(:project, :private, :repository, group: group) }

        context 'and user is a guest' do
          before do
            group.add_guest(current_user)
          end

          it 'raises an error' do
            expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end
    end

    context 'when user is a maintainer of a different project' do
      before do
        create(:project_empty_repo).add_maintainer(current_user)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end

  def expect_to_contain_deltas(expected_deltas)
    expect(deltas.count).to eq(expected_deltas.count)
    expect(deltas).to include(*expected_deltas) unless expected_deltas.empty?
  end
end
