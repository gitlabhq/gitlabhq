# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::ReviewerResolver do
  let(:workflow) { instance_double(Gitlab::PrinciplesDistiller::Sync::Workflow) }
  let(:resolver) do
    described_class.new(
      workflow: workflow,
      distillation_base_sha: '2222222222222222222222222222222222222222'
    )
  end

  describe '#ssot_authors' do
    subject(:authors) { resolver.ssot_authors(affected_entries) }

    let(:affected_entries) do
      {
        'qa' => {
          config: { 'sources' => [{ 'path' => 'doc/development/qa.md' }] },
          changed_sources: [{ 'path' => 'doc/development/qa.md' }],
          prior_sha: '1111111111111111111111111111111111111111'
        }
      }
    end

    before do
      allow(workflow).to receive_messages(
        gitlab_host: 'https://gitlab.com',
        catalog_project_path: 'gitlab-org/gitlab',
        default_branch: 'master'
      )
    end

    # Builds the `commits(...)` GraphQL response payload for the single
    # `p0` alias used by these single-source fixtures.
    def commits_response(authors, has_next_page: false)
      {
        'project' => {
          'repository' => {
            'p0' => {
              'nodes' => authors.map.with_index do |author, index|
                { 'author' => author, 'authoredDate' => authored_date(index) }
              end,
              'pageInfo' => { 'hasNextPage' => has_next_page }
            }
          }
        }
      }
    end

    context 'when an author has no public email' do
      # GraphQL's `Commit.author` resolves through
      # `User.by_any_email(confirmed: true)`, which matches private and
      # secondary emails too, so the commit author is still found even though
      # the account has no public_email set.
      before do
        allow(workflow).to receive(:query_graphql)
          .and_return(commits_response([{ 'id' => 'gid://gitlab/User/1', 'username' => 'eread', 'bot' => false }]))
      end

      it 'pings the author despite the account having no public email' do
        expect(authors).to eq([{ username: 'eread', id: 1 }])
      end
    end

    context 'when a prior SHA is reachable and authors resolve to users' do
      before do
        allow(workflow).to receive(:query_graphql).and_return(
          commits_response([
            { 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false },
            { 'id' => 'gid://gitlab/User/2', 'username' => 'grace', 'bot' => false },
            { 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false }
          ])
        )
      end

      it 'returns deduped @username mentions by most recent commit' do
        expect(authors).to eq([{ username: 'ada', id: 1 }, { username: 'grace', id: 2 }])
      end
    end

    context 'when an author is a bot or has a non-pingable username' do
      before do
        allow(workflow).to receive(:query_graphql).and_return(
          commits_response([
            { 'id' => 'gid://gitlab/User/1', 'username' => 'some-bot', 'bot' => true },
            { 'id' => 'gid://gitlab/User/2', 'username' => 'service-modelops-agent-principles-distiller',
              'bot' => false },
            { 'id' => 'gid://gitlab/User/3', 'username' => 'gitlab-release-tools-bot', 'bot' => false },
            { 'id' => 'gid://gitlab/User/4', 'username' => 'ada', 'bot' => false }
          ])
        )
      end

      it 'excludes bot accounts, deny-listed service accounts, and bot-suffixed usernames' do
        expect(authors).to eq([{ username: 'ada', id: 4 }])
      end
    end

    context 'when a commit has no linked GitLab account' do
      before do
        allow(workflow).to receive(:query_graphql)
          .and_return(commits_response([nil, { 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false }]))
      end

      it 'drops the unlinked commit (falls back to team ping upstream)' do
        expect(authors).to eq([{ username: 'ada', id: 1 }])
      end
    end

    context 'when the commit range for a path has more pages than AUTHOR_LOOKUP_PAGE_SIZE' do
      before do
        allow(workflow).to receive(:query_graphql)
          .and_return(commits_response([{ 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false }],
            has_next_page: true))
      end

      it 'still returns the authors from the first page but warns about the truncation', :aggregate_failures do
        expect { expect(authors).to eq([{ username: 'ada', id: 1 }]) }
          .to output(%r{doc/development/qa\.md has more than \d+ commits}).to_stderr
      end
    end

    context 'when a commit has no authored date' do
      before do
        allow(workflow).to receive(:query_graphql).and_return(
          'project' => {
            'repository' => {
              'p0' => commits_connection([
                ['unknown-date', 1, nil],
                ['dated', 2, '2026-08-20T00:00:00Z']
              ])
            }
          }
        )
      end

      it 'ranks the author after dated commits' do
        expect(authors).to eq([{ username: 'dated', id: 2 }, { username: 'unknown-date', id: 1 }])
      end
    end

    context 'when there is no reachable prior SHA' do
      let(:affected_entries) do
        { 'qa' => { config: {}, changed_sources: [{ 'path' => 'doc/development/qa.md' }], prior_sha: nil } }
      end

      it 'returns no mentions without querying GraphQL' do
        expect(workflow).not_to receive(:query_graphql)
        expect(authors).to eq([])
      end
    end

    context 'when the range is unreachable (e.g. prior_sha predates the fetched history)' do
      before do
        # Workflow#query_graphql mirrors the existing warn-and-return-nil
        # policy on GraphQL::Error / transport failure (see Workflow#graphql).
        allow(workflow).to receive(:query_graphql).and_return(nil)
      end

      it 'returns no mentions instead of raising' do
        expect(authors).to eq([])
      end
    end

    context 'when a principle has more sources than the batch size' do
      let(:many_paths) { (1..12).map { |i| "doc/development/topic-#{i}.md" } }
      let(:affected_entries) do
        {
          'backend-ruby' => {
            config: {},
            changed_sources: many_paths.map { |p| { 'path' => p } },
            prior_sha: '1111111111111111111111111111111111111111'
          }
        }
      end

      it 'splits the request into batches within AUTHOR_LOOKUP_BATCH_SIZE aliases each', :aggregate_failures do
        batch_sizes = []
        allow(workflow).to receive(:query_graphql) do |query, _variables|
          batch_sizes << query.scan(/^\s*p\d+:/).size
          commits_response([{ 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false }])
        end

        expect(authors).to eq([{ username: 'ada', id: 1 }])
        expect(batch_sizes).to eq([
          described_class::AUTHOR_LOOKUP_BATCH_SIZE,
          many_paths.size - described_class::AUTHOR_LOOKUP_BATCH_SIZE
        ])
      end
    end

    context 'when authors changed multiple source paths' do
      let(:affected_entries) do
        {
          'graphql' => {
            config: {},
            changed_sources: [
              { 'path' => 'doc/development/api_graphql_styleguide.md' },
              { 'path' => 'doc/development/graphql_guide/reviewing.md' }
            ],
            prior_sha: '1111111111111111111111111111111111111111'
          }
        }
      end

      it 'ranks authors across all paths before applying the cap' do
        allow(workflow).to receive(:query_graphql).and_return(
          'project' => {
            'repository' => {
              'p0' => commits_connection([
                ['ada', 1, '2026-08-20T00:00:00Z'],
                ['grace', 2, '2026-08-19T00:00:00Z'],
                ['linus', 3, '2026-08-18T00:00:00Z'],
                ['marge', 4, '2026-08-17T00:00:00Z']
              ]),
              'p1' => commits_connection([['jessie', 5, '2026-08-21T00:00:00Z']])
            }
          }
        )

        expect(authors).to eq([
          { username: 'jessie', id: 5 },
          { username: 'ada', id: 1 },
          { username: 'grace', id: 2 },
          { username: 'linus', id: 3 }
        ])
      end

      it 'keeps each author at their most recent commit date' do
        allow(workflow).to receive(:query_graphql).and_return(
          'project' => {
            'repository' => {
              'p0' => commits_connection([['ada', 1, '2026-08-18T00:00:00Z']]),
              'p1' => commits_connection([
                ['grace', 2, '2026-08-20T00:00:00Z'],
                ['ada', 1, '2026-08-21T00:00:00Z']
              ])
            }
          }
        )

        expect(authors).to eq([{ username: 'ada', id: 1 }, { username: 'grace', id: 2 }])
      end
    end
  end

  describe '#ssot_authors author limits' do
    subject(:authors) { resolver.ssot_authors(affected_entries) }

    let(:affected_entries) do
      {
        'qa' => {
          config: { 'sources' => [{ 'path' => 'doc/development/qa.md' }] },
          changed_sources: [{ 'path' => 'doc/development/qa.md' }],
          prior_sha: '1111111111111111111111111111111111111111'
        }
      }
    end

    before do
      allow(workflow).to receive(:catalog_project_path).and_return('gitlab-org/gitlab')
    end

    it 'caps resolved authors at four' do
      allow(workflow).to receive(:query_graphql).and_return(commits_response([
        { 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false },
        { 'id' => 'gid://gitlab/User/2', 'username' => 'grace', 'bot' => false },
        { 'id' => 'gid://gitlab/User/3', 'username' => 'linus', 'bot' => false },
        { 'id' => 'gid://gitlab/User/4', 'username' => 'marge', 'bot' => false },
        { 'id' => 'gid://gitlab/User/5', 'username' => 'mats', 'bot' => false }
      ]))

      expect(authors).to eq([
        { username: 'ada', id: 1 }, { username: 'grace', id: 2 },
        { username: 'linus', id: 3 }, { username: 'marge', id: 4 }
      ])
    end

    it 'keeps an author with an unparseable ID' do
      allow(workflow).to receive(:query_graphql)
        .and_return(commits_response([{ 'id' => 'invalid', 'username' => 'ada', 'bot' => false }]))

      expect { expect(authors).to eq([{ username: 'ada', id: nil }]) }
        .to output(/could not resolve reviewer ID for SSOT author @ada/).to_stderr
    end

    it 'keeps an author with a non-string authored date' do
      response = commits_response([{ 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false }])
      response.dig('project', 'repository', 'p0', 'nodes').first['authoredDate'] = 123
      allow(workflow).to receive(:query_graphql).and_return(response)

      expect(authors).to eq([{ username: 'ada', id: 1 }])
    end
  end

  describe '#owner_team_reviewer' do
    subject(:reviewer) { resolver.owner_team_reviewer(team) }

    let(:team) { '@gitlab-org/maintainers/ai-harness' }

    it 'chooses the available member with the fewest open review requests' do
      allow(workflow).to receive(:query_graphql).and_return(
        'group' => {
          'groupMembers' => {
            'nodes' => [
              { 'user' => { 'id' => 'gid://gitlab/User/1', 'username' => 'busy', 'bot' => false,
                            'state' => 'active', 'status' => { 'availability' => 'BUSY' },
                            'reviewRequestedMergeRequests' => { 'count' => 0 } } },
              { 'user' => { 'id' => 'gid://gitlab/User/2', 'username' => 'grace', 'bot' => false,
                            'state' => 'active', 'status' => { 'availability' => 'NOT_SET' },
                            'reviewRequestedMergeRequests' => { 'count' => 3 } } },
              { 'user' => { 'id' => 'gid://gitlab/User/3', 'username' => 'ada', 'bot' => false,
                            'state' => 'active', 'status' => { 'availability' => 'NOT_SET' },
                            'reviewRequestedMergeRequests' => { 'count' => 1 } } }
            ]
          }
        }
      )

      expect(reviewer).to eq(username: 'ada', id: 3, review_count: 1)
    end

    it 'does not choose a bot-suffixed member as the fallback reviewer' do
      allow(workflow).to receive(:query_graphql).and_return(
        'group' => {
          'groupMembers' => {
            'nodes' => [
              { 'user' => { 'id' => 'gid://gitlab/User/1', 'username' => 'gitlab-release-tools-bot', 'bot' => false,
                            'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 0 } } },
              { 'user' => { 'id' => 'gid://gitlab/User/2', 'username' => 'ada', 'bot' => false,
                            'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 1 } } }
            ]
          }
        }
      )

      expect(reviewer).to eq(username: 'ada', id: 2, review_count: 1)
    end

    it 'warns and returns nil when a group cannot be resolved' do
      allow(workflow).to receive(:query_graphql).and_return('group' => nil)

      expect { expect(reviewer).to be_nil }
        .to output(%r{could not resolve owner team @gitlab-org/maintainers/ai-harness}).to_stderr
    end

    it 'selects the lowest-load member across all group member pages', :aggregate_failures do
      allow(workflow).to receive(:query_graphql).and_return(
        {
          'group' => {
            'groupMembers' => {
              'nodes' => [
                { 'user' => { 'id' => 'gid://gitlab/User/1', 'username' => 'grace', 'bot' => false,
                              'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 3 } } }
              ],
              'pageInfo' => { 'hasNextPage' => true, 'endCursor' => 'page-one' }
            }
          }
        },
        {
          'group' => {
            'groupMembers' => {
              'nodes' => [
                { 'user' => { 'id' => 'gid://gitlab/User/2', 'username' => 'ada', 'bot' => false,
                              'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 1 } } }
              ],
              'pageInfo' => { 'hasNextPage' => false, 'endCursor' => nil }
            }
          }
        }
      )

      expect(reviewer).to eq(username: 'ada', id: 2, review_count: 1)
      expect(workflow).to have_received(:query_graphql)
        .with(anything, **{ fullPath: 'gitlab-org/maintainers/ai-harness', after: 'page-one' }).once
    end

    it 'selects from completed pages when a later page cannot be resolved' do
      allow(workflow).to receive(:query_graphql).and_return(
        {
          'group' => {
            'groupMembers' => {
              'nodes' => [
                { 'user' => { 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false,
                              'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 1 } } }
              ],
              'pageInfo' => { 'hasNextPage' => true, 'endCursor' => 'page-one' }
            }
          }
        },
        nil
      )

      expect { expect(reviewer).to eq(username: 'ada', id: 1, review_count: 1) }
        .to output(/could not fully resolve owner team/).to_stderr
    end

    it 'selects from completed pages when the group exceeds the page limit' do
      stub_const("#{described_class}::OWNER_TEAM_MAX_PAGES", 1)
      allow(workflow).to receive(:query_graphql).and_return(
        'group' => {
          'groupMembers' => {
            'nodes' => [
              { 'user' => { 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false,
                            'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 1 } } }
            ],
            'pageInfo' => { 'hasNextPage' => true, 'endCursor' => 'page-one' }
          }
        }
      )

      expect { expect(reviewer).to eq(username: 'ada', id: 1, review_count: 1) }
        .to output(/has more than 100 direct members/).to_stderr
    end

    context 'with individual owner handles' do
      let(:team) { '@ada @grace' }

      it 'resolves individual users in one query and selects the lowest-load member', :aggregate_failures do
        allow(workflow).to receive(:query_graphql).and_return(
          'users' => {
            'nodes' => [
              { 'id' => 'gid://gitlab/User/1', 'username' => 'ada', 'bot' => false,
                'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 2 } },
              { 'id' => 'gid://gitlab/User/2', 'username' => 'grace', 'bot' => false,
                'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 1 } }
            ]
          }
        )

        expect(reviewer).to eq(username: 'grace', id: 2, review_count: 1)
        expect(workflow).to have_received(:query_graphql).once
      end
    end

    context 'with group and individual owner handles' do
      let(:team) { '@gitlab-org/maintainers/ai-harness @ada @grace' }

      it 'queries each handle type once and chooses across both sets', :aggregate_failures do
        allow(workflow).to receive(:query_graphql).and_return(
          { 'group' => { 'groupMembers' => { 'nodes' => [
            { 'user' => { 'id' => 'gid://gitlab/User/1', 'username' => 'group-member', 'bot' => false,
                          'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 2 } } }
          ] } } },
          { 'users' => { 'nodes' => [
            { 'id' => 'gid://gitlab/User/2', 'username' => 'ada', 'bot' => false,
              'state' => 'active', 'reviewRequestedMergeRequests' => { 'count' => 1 } },
            { 'id' => 'gid://gitlab/User/3', 'username' => 'busy', 'bot' => false,
              'state' => 'active', 'status' => { 'availability' => 'BUSY' },
              'reviewRequestedMergeRequests' => { 'count' => 0 } }
          ] } }
        )

        expect(reviewer).to eq(username: 'ada', id: 2, review_count: 1)
        expect(workflow).to have_received(:query_graphql).twice
      end
    end
  end

  def commits_response(authors, has_next_page: false)
    {
      'project' => {
        'repository' => {
          'p0' => {
            'nodes' => authors.map.with_index do |author, index|
              { 'author' => author, 'authoredDate' => authored_date(index) }
            end,
            'pageInfo' => { 'hasNextPage' => has_next_page }
          }
        }
      }
    }
  end

  def commits_connection(entries)
    {
      'nodes' => entries.map do |username, id, authored_date|
        {
          'author' => { 'id' => "gid://gitlab/User/#{id}", 'username' => username, 'bot' => false },
          'authoredDate' => authored_date
        }
      end,
      'pageInfo' => { 'hasNextPage' => false }
    }
  end

  def authored_date(index)
    (Time.utc(2026, 8, 20) - (index * 86_400)).iso8601
  end
end
