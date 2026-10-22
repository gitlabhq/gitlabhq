# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::BlameResolver, :clean_gitlab_redis_rate_limiting, feature_category: :source_code_management do
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

    let(:request) { ActionDispatch::TestRequest.create }

    subject(:resolve_blame) do
      resolve(described_class, obj: blob, args: args, ctx: { current_user: user, request: request })
    end

    context 'when unauthorized' do
      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_blame
        end
      end

      it 'does not consume the rate limit budget' do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled_request?)

        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_blame
        end
      end
    end

    context 'when anonymous with no request in the context' do
      let_it_be(:public_project) { create(:project, :public, :repository) }

      let(:project) { public_project }
      let(:user) { nil }
      let(:request) { nil }

      shared_examples 'denies without consulting the limiter' do
        it 'denies without consulting the limiter' do
          expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

          expect_graphql_error_to_be_created(
            Gitlab::Graphql::Errors::ResourceNotAvailable,
            'This endpoint has been requested too many times. Try again later.'
          ) { resolve_blame }
        end
      end

      context 'when the ActionCable worker has set an IP address' do
        it 'counts against the per-IP limit' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
            .with(:project_repositories_blame_unauthenticated, scope: { ip: '198.51.100.1' })
            .and_return(false)

          Gitlab::IpAddressState.with('198.51.100.1') do
            expect(resolve_blame).to be_an_instance_of(Gitlab::Blame)
          end
        end
      end

      context 'when no IP address is available' do
        it_behaves_like 'denies without consulting the limiter'
      end

      # Gitlab::Middleware::IpAddress stores remote_ip.to_s, so the state can be blank
      # rather than nil, which would key every anonymous caller to one bucket.
      context 'when the IP address is blank' do
        around do |example|
          Gitlab::IpAddressState.with('') { example.run }
        end

        it_behaves_like 'denies without consulting the limiter'
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

      context 'when the context has no request' do
        let(:request) { nil }

        it 'still counts against the limit, without logging the request' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
            .with(:project_repositories_blame, scope: { user: user, project: project })
            .and_return(true)
          expect(Gitlab::AuthLogger).not_to receive(:error)

          expect_graphql_error_to_be_created(
            Gitlab::Graphql::Errors::ResourceNotAvailable,
            'This endpoint has been requested too many times. Try again later.'
          ) { resolve_blame }
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

        context 'when blame_line_range_cap_1000 feature flag is disabled' do
          before do
            stub_feature_flags(blame_line_range_cap_1000: false)
          end

          context 'when difference between to_line and from_line is greater than 99' do
            let(:args) { { from_line: 3, to_line: 103 } }

            it_behaves_like 'argument error',
              '`to_line` must be greater than or equal to `from_line` and smaller than `from_line` + 100'
          end
        end

        context 'when blame_line_range_cap_1000 feature flag is enabled' do
          before do
            stub_feature_flags(blame_line_range_cap_1000: true)
          end

          context 'when difference between to_line and from_line is within new cap' do
            let(:args) { { from_line: 1, to_line: 999 } }

            it 'returns blame object' do
              expect(resolve_blame).to be_an_instance_of(Gitlab::Blame)
            end
          end

          context 'when difference between to_line and from_line is at the exact upper boundary' do
            let(:args) { { from_line: 1, to_line: 1000 } }

            it 'returns blame object' do
              expect(resolve_blame).to be_an_instance_of(Gitlab::Blame)
            end
          end

          context 'when difference between to_line and from_line exceeds new cap' do
            let(:args) { { from_line: 1, to_line: 1001 } }

            it_behaves_like 'argument error',
              '`to_line` must be greater than or equal to `from_line` and smaller than `from_line` + 1000'
          end
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
