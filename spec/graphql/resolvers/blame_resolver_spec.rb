# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BlameResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }

    let(:path) { 'files/ruby/popen.rb' }
    let(:commit) { project.commit('master') }
    let(:blob) { project.repository.blob_at(commit.id, path) }
    let(:ignore_revs) { false }
    let(:from_line) { 1 }
    let(:to_line) { 100 }
    let(:args) { { from_line: from_line, to_line: to_line, ignore_revs: ignore_revs } }
    let(:first_line_blame_commit) do
      Gitlab::Blame.new(blob, commit, range: (1..1), ignore_revs: false).groups.dig(0, :commit)
    end

    let(:first_line_ignored_blame_commit) do
      Gitlab::Blame.new(blob, commit, range: (1..1), ignore_revs: true).groups.dig(0, :commit)
    end

    subject(:resolve_blame) { resolve(described_class, obj: blob, args: args, ctx: { current_user: user }) }

    context 'when unauthorized' do
      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_blame
        end
      end
    end

    context 'when authorized' do
      before_all do
        project.add_developer(user)
      end

      shared_examples 'argument error' do |error_message|
        it 'raises an ArgumentError' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, error_message) { resolve_blame }
        end
      end

      shared_examples 'graphql execution error' do |error_message|
        it 'raises a GraphQL::ExecutionError' do
          expect_graphql_error_to_be_created(GraphQL::ExecutionError, error_message) { resolve_blame }
        end
      end

      context 'when feature is enabled' do
        context 'when from_line is below 1' do
          let(:args) { { from_line: 0, to_line: 2 } }

          it_behaves_like 'argument error', '`from_line` and `to_line` must be greater than or equal to 1'
        end

        context 'when to_line is below 1' do
          let(:args) { { from_line: 1, to_line: 0 } }

          it_behaves_like 'argument error', '`from_line` and `to_line` must be greater than or equal to 1'
        end

        context 'when to_line less than from_line' do
          let(:args) { { from_line: 3, to_line: 1 } }

          it_behaves_like 'argument error', '`to_line` must be greater than or equal to `from_line`'
        end

        context 'when difference between to_line and from_line is greater then 99' do
          let(:args) { { from_line: 3, to_line: 103 } }

          it_behaves_like 'argument error',
            '`to_line` must be greater than or equal to `from_line` and smaller than `from_line` + 100'
        end

        context 'when to_line and from_line are the same' do
          let(:args) { { from_line: 1, to_line: 1 } }

          it 'returns blame object' do
            expect(resolve_blame).to be_an_instance_of(Gitlab::Blame)
          end
        end

        context 'when ignore_revs is false' do
          let(:ignore_revs) { false }

          before do
            project.repository.commit_files(
              user,
              branch_name: 'master',
              message: 'Add file',
              actions: [
                {
                  action: :create,
                  file_path: '.git-blame-ignore-revs',
                  content: first_line_blame_commit.id
                }
              ]
            )
          end

          after do
            project.repository.commit_files(
              user,
              branch_name: 'master',
              message: 'Delete file',
              actions: [
                {
                  action: :delete,
                  file_path: '.git-blame-ignore-revs'
                }
              ]
            )
          end

          it 'returns blame object', :aggregate_failures do
            expect(first_line_blame_commit).to eq(first_line_ignored_blame_commit)
            blame = resolve_blame
            expect(blame).to be_an_instance_of(Gitlab::Blame)
            expect(blame.groups.dig(0, :commit).id).to eq(first_line_blame_commit.id)
          end
        end

        context 'when ignore_revs is true' do
          let(:ignore_revs) { true }

          context 'and the ignore revs file does not exist' do
            it_behaves_like 'graphql execution error',
              'Could not resolve ignore-revisions file (`refs/heads/master:.git-blame-ignore-revs`).'
          end

          context 'and the ignore revs file contains invalid revisions' do
            before do
              project.repository.commit_files(
                user,
                branch_name: 'master',
                message: 'Add file',
                actions: [
                  {
                    action: :create,
                    file_path: '.git-blame-ignore-revs',
                    content: 'uasdf8werk234asdf88'
                  }
                ]
              )
            end

            after do
              project.repository.commit_files(
                user,
                branch_name: 'master',
                message: 'Delete file',
                actions: [
                  {
                    action: :delete,
                    file_path: '.git-blame-ignore-revs'
                  }
                ]
              )
            end

            it_behaves_like 'graphql execution error',
              'The ignore-revisions file (`refs/heads/master:.git-blame-ignore-revs`) contains invalid revisions.'
          end

          context 'and the ignore revs file contains valid revisions' do
            before do
              project.repository.commit_files(
                user,
                branch_name: 'master',
                message: 'Add file',
                actions: [
                  {
                    action: :create,
                    file_path: '.git-blame-ignore-revs',
                    content: first_line_blame_commit.id
                  }
                ]
              )
            end

            after do
              project.repository.commit_files(
                user,
                branch_name: 'master',
                message: 'Delete file',
                actions: [
                  {
                    action: :delete,
                    file_path: '.git-blame-ignore-revs'
                  }
                ]
              )
            end

            it 'returns blame object', :aggregate_failures do
              expect(first_line_blame_commit).to eq(first_line_ignored_blame_commit)
              blame = resolve_blame
              expect(blame).to be_an_instance_of(Gitlab::Blame)
              expect(blame.groups.dig(0, :commit).id).to eq(first_line_ignored_blame_commit.id)
            end
          end
        end
      end
    end
  end
end
