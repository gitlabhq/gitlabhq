# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../support/tmpdir'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

# AutoMr is mixed into Sync via `include`, so its methods only mean
# anything on a Sync instance. The file path (sync/auto_mr_spec.rb)
# signals the subject matter; the described_class reflects what the
# tests actually exercise.
RSpec.describe Gitlab::PrinciplesDistiller::Sync do # rubocop:disable RSpec/SpecFilePathFormat -- subject-matter grouping (AutoMr) overrides path/class match
  include TmpdirHelper

  # rubocop:disable RSpec/EnvAssignment -- ENV assignment is necessary in `around` blocks; stub_env requires `allow` which is not available outside `before`
  around do |example|
    original_branch = ENV['CI_DEFAULT_BRANCH']
    ENV['CI_DEFAULT_BRANCH'] ||= 'master'
    example.run
  ensure
    ENV['CI_DEFAULT_BRANCH'] = original_branch
  end
  # rubocop:enable RSpec/EnvAssignment

  let(:tmpdir) { mktmpdir }
  let(:sync) { described_class.new }

  describe '.principle_diff_section' do
    subject(:section) { sync.principle_diff_section(name, affected_entry, default_branch) }

    let(:name) { 'code-review' }
    let(:default_branch) { 'master' }
    let(:project_url) { 'https://gitlab.com/gitlab-org/gitlab' }

    before do
      allow(sync.workflow).to receive_messages(
        gitlab_host: 'https://gitlab.com',
        catalog_project_path: 'gitlab-org/gitlab'
      )
      # Stub git interactions so tests don't shell out.
      allow(sync).to receive_messages(
        distillation_base_sha: 'abcdef1234567890abcdef1234567890abcdef12',
        compute_principle_diff: [nil, false]
      )
    end

    context 'with sources and a prior SHA' do
      let(:affected_entry) do
        {
          changed_sources: [
            { 'path' => 'doc/development/code_review.md' },
            { 'path' => 'doc/development/contributing/merge_request_workflow.md' }
          ],
          prior_sha: '9ab16c7588f7d32fdb6d509a70bae72309346826'
        }
      end

      it 'starts with the principle name as a Markdown subheading' do
        expect(section).to start_with('#### `code-review`')
      end

      it 'includes a commits link per source path', :aggregate_failures do
        expect(section).to include(
          "- [`doc/development/code_review.md`](#{project_url}/-/commits/master/doc/development/code_review.md)"
        )
        expect(section).to include(
          "- [`doc/development/contributing/merge_request_workflow.md`](" \
            "#{project_url}/-/commits/master/doc/development/contributing/merge_request_workflow.md)"
        )
      end

      it 'wraps the file list in a <details> block with a count summary' do
        expect(section).to include('<details><summary>Source files (2)</summary>')
        expect(section).to include('</details>')
      end

      it 'does NOT include the broad project-wide compare link (it was unhelpful at scale)' do
        expect(section).not_to include('/-/compare/')
        expect(section).not_to include('Compare SSOT changes')
      end
    end

    context 'when a per-principle SSOT diff is available' do
      let(:affected_entry) do
        {
          changed_sources: [{ 'path' => 'doc/development/code_review.md' }],
          prior_sha: '9ab16c7588f7d32fdb6d509a70bae72309346826'
        }
      end

      let(:diff_text) { "diff --git a/doc/development/code_review.md b/doc/development/code_review.md\n+new line\n" }

      before do
        allow(sync).to receive(:compute_principle_diff).and_return([diff_text, false])
      end

      it 'embeds the diff in a <details> block with both range SHAs in the summary', :aggregate_failures do
        expect(section).to include('<details><summary>SSOT diff since previous distillation ' \
          "(9ab16c7588f7 \u2192 abcdef123456)</summary>")
        expect(section).to include('````diff')
        expect(section).to include(diff_text.chomp)
      end

      it 'shows the resolved current-tip SHA (not the branch name) so the range stays meaningful' do
        expect(section).not_to match(/SSOT diff since previous distillation \([0-9a-f]+ \u2192 master\)/)
      end

      it 'uses a 4-backtick fence so embedded ``` blocks in SSOT files do not close it prematurely' do
        expect(section).to include('````diff')
        expect(section).to include('````')
      end
    end

    context 'when the diff is truncated' do
      let(:affected_entry) do
        {
          changed_sources: [{ 'path' => 'doc/development/code_review.md' }],
          prior_sha: '9ab16c7588f7d32fdb6d509a70bae72309346826'
        }
      end

      before do
        allow(sync).to receive(:compute_principle_diff).and_return(["a long diff\n", true])
      end

      it 'appends a truncation footer pointing at the per-file links' do
        expect(section).to include('diff truncated at')
        expect(section).to include('per-file commit-history links')
      end
    end

    context 'without a prior SHA' do
      let(:affected_entry) do
        { changed_sources: [{ 'path' => 'doc/foo.md' }], prior_sha: nil }
      end

      it 'still includes the per-file commits link' do
        expect(section).to include("- [`doc/foo.md`](#{project_url}/-/commits/master/doc/foo.md)")
      end

      it 'omits the diff section' do
        expect(section).not_to include('SSOT diff since previous distillation')
      end
    end

    context 'with no sources and no prior SHA (e.g. forced full re-distillation)' do
      let(:affected_entry) { { changed_sources: [], prior_sha: nil } }

      it 'still emits the principle heading' do
        expect(section).to include('#### `code-review`')
      end

      it 'does not crash on empty data' do
        expect { section }.not_to raise_error
      end
    end
  end

  describe '.truncate_diff' do
    it 'returns the input unchanged if both caps are honored' do
      text = "line1\nline2\n"

      result, truncated = sync.truncate_diff(text)

      expect(result).to eq(text)
      expect(truncated).to be(false)
    end

    it 'caps to DIFF_MAX_LINES when the line count exceeds the limit' do
      stub_const("#{described_class}::AutoMr::DIFF_MAX_LINES", 3)
      stub_const("#{described_class}::AutoMr::DIFF_MAX_BYTES", 10_000)
      text = "#{(1..10).map { |i| "line#{i}" }.join("\n")}\n"

      result, truncated = sync.truncate_diff(text)

      expect(result.lines.size).to eq(3)
      expect(truncated).to be(true)
    end

    it 'caps to DIFF_MAX_BYTES and trims back to a newline boundary' do
      stub_const("#{described_class}::AutoMr::DIFF_MAX_LINES", 1000)
      stub_const("#{described_class}::AutoMr::DIFF_MAX_BYTES", 12)
      text = "abcdefgh\nijklmn\nopq\n"

      result, truncated = sync.truncate_diff(text)

      expect(result).to eq("abcdefgh\n")
      expect(truncated).to be(true)
    end
  end

  describe '.find_open_mr_iid' do
    # find_open_mr_iid is a private AutoMr helper. Specs reach it via send
    # and stub the Net::HTTP transport directly (the same seam the
    # GraphqlClient spec uses).
    subject(:iid) do
      sync.send(:find_open_mr_iid, 'gitlab-org%2Fgitlab', 'feature-branch', 'api-token')
    end

    let(:fake_response) { instance_double(Net::HTTPResponse, code: '200', body: response_body) }
    let(:http_instance) { instance_double(Net::HTTP) }
    let(:captured_request) { [] }

    before do
      allow(sync.workflow).to receive(:gitlab_host).and_return('https://gitlab.com')
      allow(Net::HTTP).to receive(:new).and_return(http_instance)
      allow(http_instance).to receive(:use_ssl=)
      allow(http_instance).to receive(:read_timeout=)
      allow(http_instance).to receive(:request) do |request|
        captured_request << request
        fake_response
      end
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(http_success)
    end

    context 'when the API returns one open MR' do
      let(:http_success) { true }
      let(:response_body) { '[{"iid":42}]' }

      it 'returns the iid' do
        expect(iid).to eq(42)
      end
    end

    context 'when the API returns an empty array' do
      let(:http_success) { true }
      let(:response_body) { '[]' }

      it 'returns nil' do
        expect(iid).to be_nil
      end
    end

    context 'when the API returns a non-2xx response' do
      let(:http_success) { false }
      let(:response_body) { 'Internal Server Error' }

      it 'returns nil' do
        expect(iid).to be_nil
      end
    end

    context 'on URL construction' do
      let(:http_success) { true }
      let(:response_body) { '[]' }

      it 'sends order_by=created_at and sort=desc so the result is deterministic',
        :aggregate_failures do
        iid

        query = captured_request.first.uri.query
        expect(query).to include('state=opened')
        expect(query).to include('source_branch=feature-branch')
        expect(query).to include('order_by=created_at')
        expect(query).to include('sort=desc')
      end

      it 'sends the PRIVATE-TOKEN header' do
        iid

        expect(captured_request.first['PRIVATE-TOKEN']).to eq('api-token')
      end
    end
  end

  describe '.mr_assignee_id' do
    subject(:assignee_id) { sync.send(:mr_assignee_id, 'api-token') }

    let(:fake_response) { instance_double(Net::HTTPResponse, code: '200', body: response_body) }
    let(:http_instance) { instance_double(Net::HTTP) }
    let(:captured_request) { [] }

    before do
      allow(sync.workflow).to receive(:gitlab_host).and_return('https://gitlab.com')
      allow(Net::HTTP).to receive(:new).and_return(http_instance)
      allow(http_instance).to receive(:use_ssl=)
      allow(http_instance).to receive(:read_timeout=)
      allow(http_instance).to receive(:request) do |request|
        captured_request << request
        fake_response
      end
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(http_success)
    end

    context 'when GET /user succeeds' do
      let(:http_success) { true }
      let(:response_body) { '{"id":4242,"username":"service-account"}' }

      it 'returns the current user id', :aggregate_failures do
        expect(assignee_id).to eq(4242)
        expect(captured_request.first.uri.to_s).to eq('https://gitlab.com/api/v4/user')
        expect(captured_request.first['PRIVATE-TOKEN']).to eq('api-token')
      end
    end

    context 'when GET /user fails' do
      let(:http_success) { false }
      let(:response_body) { 'Too Many Requests' }

      it 'returns nil so the MR is created unassigned' do
        expect(assignee_id).to be_nil
      end

      it 'memoizes the nil result so a fan-out run does not re-query', :aggregate_failures do
        2.times { sync.send(:mr_assignee_id, 'api-token') }

        expect(captured_request.size).to eq(1)
      end
    end
  end

  describe '.version_milestone_title' do
    subject(:title) { sync.send(:version_milestone_title) }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
    end

    context 'when VERSION holds a pre-release version' do
      before do
        File.write(File.join(tmpdir, 'VERSION'), "19.1.0-pre\n")
      end

      it 'returns MAJOR.MINOR' do
        expect(title).to eq('19.1')
      end
    end

    context 'when VERSION holds a plain version' do
      before do
        File.write(File.join(tmpdir, 'VERSION'), "20.10.3\n")
      end

      it 'returns MAJOR.MINOR' do
        expect(title).to eq('20.10')
      end
    end

    context 'when VERSION is missing' do
      it 'returns nil' do
        expect(title).to be_nil
      end
    end

    context 'when VERSION is malformed' do
      before do
        File.write(File.join(tmpdir, 'VERSION'), "not-a-version\n")
      end

      it 'returns nil' do
        expect(title).to be_nil
      end
    end
  end

  describe '.current_milestone_id' do
    subject(:milestone_id) do
      sync.send(:current_milestone_id, 'gitlab-org%2Fgitlab', 'api-token')
    end

    let(:fake_response) { instance_double(Net::HTTPResponse, code: '200', body: response_body) }
    let(:http_instance) { instance_double(Net::HTTP) }
    let(:captured_request) { [] }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      File.write(File.join(tmpdir, 'VERSION'), "19.1.0-pre\n")
      allow(sync.workflow).to receive(:gitlab_host).and_return('https://gitlab.com')
      allow(Net::HTTP).to receive(:new).and_return(http_instance)
      allow(http_instance).to receive(:use_ssl=)
      allow(http_instance).to receive(:read_timeout=)
      allow(http_instance).to receive(:request) do |request|
        captured_request << request
        fake_response
      end
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(http_success)
    end

    context 'when a milestone matches the VERSION title' do
      let(:http_success) { true }
      let(:response_body) { '[{"id":6177882,"title":"19.1","state":"active"}]' }

      it 'returns the milestone id and queries with include_ancestors', :aggregate_failures do
        expect(milestone_id).to eq(6177882)
        query = captured_request.first.uri.query
        expect(query).to include('title=19.1')
        expect(query).to include('include_ancestors=true')
      end
    end

    context 'when no milestone matches the title' do
      let(:http_success) { true }
      let(:response_body) { '[{"id":1,"title":"18.0"}]' }

      it 'returns nil so the MR is created without a milestone' do
        expect(milestone_id).to be_nil
      end

      it 'memoizes the nil result so a fan-out run does not re-query', :aggregate_failures do
        2.times { sync.send(:current_milestone_id, 'gitlab-org%2Fgitlab', 'api-token') }

        expect(captured_request.size).to eq(1)
      end
    end

    context 'when the API returns a 2xx non-JSON response' do
      let(:http_success) { true }
      let(:response_body) { '<html>not json</html>' }

      it 'returns nil so the MR is created without a milestone' do
        expect(milestone_id).to be_nil
      end
    end

    context 'when the milestone lookup fails' do
      let(:http_success) { false }
      let(:response_body) { 'Forbidden' }

      it 'returns nil' do
        expect(milestone_id).to be_nil
      end
    end

    context 'when VERSION is missing' do
      let(:http_success) { true }
      let(:response_body) { '[]' }

      before do
        FileUtils.rm_f(File.join(tmpdir, 'VERSION'))
      end

      it 'returns nil without attempting a milestone lookup', :aggregate_failures do
        expect(milestone_id).to be_nil
        expect(captured_request).to be_empty
      end
    end
  end

  describe '.prefetch_prior_shas!' do
    # prefetch_prior_shas! is private; reach it via send. We stub
    # `sha_present_locally?` and `system` to avoid touching real git.
    subject(:prefetch) { sync.send(:prefetch_prior_shas!, affected) }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = '/tmp/workspace'
      allow(sync).to receive(:system).and_return(true)
    end

    context 'with no prior SHAs in affected' do
      let(:affected) { { 'qa' => { prior_sha: nil } } }

      it 'is a no-op' do
        prefetch

        expect(sync).not_to have_received(:system)
      end
    end

    context 'when all prior SHAs are already present locally' do
      let(:affected) do
        { 'qa' => { prior_sha: 'abc123' }, 'backend' => { prior_sha: 'def456' } }
      end

      before do
        allow(sync).to receive(:sha_present_locally?).and_return(true)
      end

      it 'does not invoke git fetch' do
        prefetch

        expect(sync).not_to have_received(:system)
          .with('git', anything, anything, 'fetch', any_args)
      end
    end

    context 'when prior SHAs are missing locally' do
      let(:affected) do
        { 'qa' => { prior_sha: 'abc123' }, 'backend' => { prior_sha: 'def456' } }
      end

      before do
        allow(sync).to receive(:sha_present_locally?).and_return(false)
      end

      it 'invokes git fetch --depth=1 origin <sha> for each missing SHA' do
        prefetch

        expect(sync).to have_received(:system)
          .with('git', '-C', '/tmp/workspace', 'fetch', '--depth=1', 'origin', 'abc123', any_args)
        expect(sync).to have_received(:system)
          .with('git', '-C', '/tmp/workspace', 'fetch', '--depth=1', 'origin', 'def456', any_args)
      end
    end

    context 'when affected has duplicate prior SHAs' do
      let(:affected) do
        {
          'qa' => { prior_sha: 'abc123' },
          'backend' => { prior_sha: 'abc123' },
          'security' => { prior_sha: 'abc123' }
        }
      end

      before do
        allow(sync).to receive(:sha_present_locally?).and_return(false)
      end

      it 'fetches each unique SHA only once' do
        prefetch

        expect(sync).to have_received(:system)
          .with('git', '-C', '/tmp/workspace', 'fetch', '--depth=1', 'origin', 'abc123', any_args)
          .once
      end
    end

    context 'when a fetch fails' do
      let(:affected) { { 'qa' => { prior_sha: 'abc123' } } }

      before do
        allow(sync).to receive(:sha_present_locally?).and_return(false)
        allow(sync).to receive(:system)
          .with('git', '-C', '/tmp/workspace', 'fetch', '--depth=1', 'origin', 'abc123', any_args)
          .and_return(false)
      end

      it 'warns but does not raise' do
        expect { prefetch }.to output(/could not fetch abc123/).to_stderr
      end
    end
  end

  describe '.push_remote_url' do
    # push_remote_url is a private AutoMr helper. Specs reach it via send.
    subject(:url) { sync.send(:push_remote_url, project_arg) }

    before do
      allow(sync.workflow).to receive(:gitlab_host).and_return(gitlab_host)
    end

    let(:gitlab_host) { 'https://gitlab.com' }

    context 'with CI_PROJECT_PATH set' do
      let(:project_arg) { '12345' }

      before do
        stub_const('ENV', 'CI_PROJECT_PATH' => 'gitlab-org/gitlab')
      end

      it 'returns a credential-free HTTPS URL using CI_PROJECT_PATH' do
        expect(url).to eq('https://gitlab.com/gitlab-org/gitlab.git')
      end
    end

    context 'without CI_PROJECT_PATH, when the project argument is a path' do
      let(:project_arg) { 'gitlab-org/gitlab' }

      before do
        stub_const('ENV', {})
      end

      it 'falls back to the path argument' do
        expect(url).to eq('https://gitlab.com/gitlab-org/gitlab.git')
      end
    end

    context 'without CI_PROJECT_PATH, when the project argument is numeric' do
      let(:project_arg) { '12345' }

      before do
        stub_const('ENV', {})
      end

      it 'aborts because numeric CI_PROJECT_ID alone is not enough' do
        expect { url }.to raise_error(SystemExit)
          .and output(/CI_PROJECT_PATH env var is required/).to_stderr
      end
    end

    context 'with a custom GITLAB_HOST' do
      let(:gitlab_host) { 'https://gitlab.example.com' }
      let(:project_arg) { '12345' }

      before do
        stub_const('ENV', 'CI_PROJECT_PATH' => 'group/repo')
      end

      it 'uses the host from workflow.gitlab_host' do
        expect(url).to eq('https://gitlab.example.com/group/repo.git')
      end
    end
  end

  describe '.create_branch_and_mr' do
    subject(:create_branch_and_mr) do
      sync.create_branch_and_mr(distilled_contents, affected, auto_mr_cfg)
    end

    let(:distilled_contents) do
      { 'qa' => "---\nsource_checksum: abc\n---\n# QA Principles\n" }
    end

    let(:affected) do
      {
        'qa' => {
          config: { 'sources' => [{ 'path' => 'doc/development/qa.md' }] },
          changed_sources: [{ 'path' => 'doc/development/qa.md' }],
          prior_sha: '1111111111111111111111111111111111111111'
        }
      }
    end

    let(:auto_mr_cfg) do
      {
        'branch_prefix' => 'docs-sync/principles',
        'title_template' => 'Update AI development principles from SSOT (%{date})',
        'labels' => %w[ai-agent documentation type::maintenance],
        'remove_source_branch' => true
      }
    end

    let(:mock_response) do
      instance_double(Net::HTTPResponse, is_a?: true, body: '{"web_url":"https://gitlab.com/foo"}', code: '201')
    end

    let(:received_body) { capture_post_body }

    before do
      stub_const('ENV', { 'GITLAB_API_TOKEN' => 'token', 'CI_PROJECT_ID' => 'gitlab-org/gitlab',
                          'CI_DEFAULT_BRANCH' => 'master', 'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
                          'CI_PROJECT_DIR' => '/tmp/workspace' })

      # Stub git invocations and the MR-create REST call so the test
      # exercises the full method body without touching the network or
      # the working tree. `git_has_staged_changes?` returns true so the
      # tooling MR is exercised too; `regenerate_static_artifacts` is a
      # no-op (its own unit tests live in manifest_spec). TOOLING_PATHS are
      # reported as present so the empty-guard in publish_tooling_branch
      # doesn't short-circuit (overridden in the no-tooling-files context).
      allow(File).to receive(:write)
      allow(File).to receive(:exist?).and_call_original
      # Treat the TOOLING_PATHS parent dirs as non-symlinked so
      # stageable_tooling_path? keeps them (realpath == dir).
      allow(File).to receive(:realpath) { |arg| arg }
      described_class::Manifest::TOOLING_PATHS.each do |path|
        allow(File).to receive(:exist?)
          .with(Gitlab::PrinciplesDistiller::Workspace.safe_join(path)).and_return(true)
      end
      allow(sync).to receive_messages(
        system: true,
        distillation_base_sha: 'abcdef1234567890abcdef1234567890abcdef12',
        regenerate_static_artifacts: nil,
        git_has_staged_changes?: true
      )
      allow(sync.workflow).to receive_messages(
        post_json: mock_response,
        gitlab_host: 'https://gitlab.com',
        catalog_project_path: 'gitlab-org/gitlab',
        default_branch: 'master'
      )

      # Drive the real grouping logic from a minimal manifest fixture so
      # team/branch derivation is exercised end-to-end. owner_team is the
      # fan-out grouping key; team_slug gives a readable branch/title suffix.
      sync.manifest.data = {
        'principles' => {
          'qa' => {
            'owner_team' => '@abdwdd @alexpooley', 'team_slug' => 'qa',
            'sources' => [{ 'path' => 'doc/development/qa.md' }]
          }
        }
      }
      allow(sync.manifest).to receive(:principles_path) { |n| ".ai/principles/distilled/#{n}.md" }
      # Keep the idempotency lookup hermetic (no network); nil => create path.
      allow(sync).to receive(:find_open_mr_iid).and_return(nil)
    end

    # Captures the team MR body (the one whose title is NOT the tooling MR),
    # since the fan-out now also opens a separate tooling MR.
    def capture_post_body
      captured = nil
      allow(sync.workflow).to receive(:post_json) do |_url, body:, **|
        captured = body unless body[:title].to_s.start_with?('tooling: ')
        mock_response
      end
      create_branch_and_mr
      captured
    end

    # Regression test for the `_affected`/`affected` rename bug
    # (https://gitlab.com/gitlab-org/gitlab/-/jobs/14279548642): the
    # method was renamed to `_affected` by rubocop autocorrect because
    # an earlier edit didn't yet reference it; subsequent edits used
    # the bare name and triggered a NameError at runtime in CI.
    it 'runs end-to-end without raising NameError on the affected parameter' do
      expect { create_branch_and_mr }.not_to raise_error
    end

    it 'opens one team MR plus the tooling MR' do
      create_branch_and_mr

      expect(sync.workflow).to have_received(:post_json).twice
    end

    it 'does not stage the Duo review-instructions file on the tooling branch' do
      staged = []
      # Mirror the default stub (return true), but record the paths passed to
      # `git add -f` so we can assert the Duo file is NOT among them.
      allow(sync).to receive(:system) do |*args, **_kwargs|
        staged.concat(args[5..]) if args[0,
          5] == ['git', '-C', Gitlab::PrinciplesDistiller::Workspace.path, 'add', '-f']

        true
      end

      create_branch_and_mr

      # The Duo fences are reconciled from merged master by the separate
      # scheduled reconcile job, so the distillation tooling branch must never
      # carry the mr-review-instructions.yaml change.
      expect(staged).not_to include(described_class::Manifest::DUO_REVIEW_INSTRUCTIONS_PATH)
    end

    it 'regenerates static artifacts without any distilled-content overrides' do
      # Fence regeneration is decoupled from distillation, so the tooling
      # branch just regenerates the manifest-driven routing tables -- no
      # in-memory distilled content is threaded through anymore.
      expect(sync).to receive(:regenerate_static_artifacts).with(no_args)

      create_branch_and_mr
    end

    context 'when the assignee and milestone lookups succeed' do
      before do
        allow(sync).to receive_messages(mr_assignee_id: 4242, current_milestone_id: 6177882)
      end

      it 'sets assignee_id and milestone_id on the MR body', :aggregate_failures do
        body = capture_post_body

        expect(body[:assignee_id]).to eq(4242)
        expect(body[:milestone_id]).to eq(6177882)
      end
    end

    context 'when the assignee and milestone lookups fail' do
      before do
        allow(sync).to receive_messages(mr_assignee_id: nil, current_milestone_id: nil)
      end

      it 'omits assignee_id and milestone_id so MR creation still proceeds', :aggregate_failures do
        body = capture_post_body

        expect(body).not_to have_key(:assignee_id)
        expect(body).not_to have_key(:milestone_id)
      end
    end

    context 'with principles spanning multiple teams' do
      let(:distilled_contents) do
        {
          'qa' => "---\nsource_checksum: a\n---\n# QA\n",
          'security' => "---\nsource_checksum: b\n---\n# Security\n"
        }
      end

      let(:affected) do
        {
          'qa' => { config: { 'sources' => [{ 'path' => 'doc/development/qa.md' }] },
                    changed_sources: [{ 'path' => 'doc/development/qa.md' }], prior_sha: nil },
          'security' => { config: { 'sources' => [{ 'path' => 'doc/development/secure.md' }] },
                          changed_sources: [{ 'path' => 'doc/development/secure.md' }], prior_sha: nil }
        }
      end

      before do
        sync.manifest.data = {
          'principles' => {
            'qa' => {
              'owner_team' => '@abdwdd @alexpooley', 'team_slug' => 'qa',
              'sources' => [{ 'path' => 'doc/development/qa.md' }]
            },
            'security' => {
              'owner_team' => '@gitlab-com/gl-security/appsec',
              'sources' => [{ 'path' => 'doc/development/secure.md' }]
            }
          }
        }
      end

      # Capture every MR body keyed by title for per-team assertions.
      def capture_all_bodies
        [].tap do |bodies|
          allow(sync.workflow).to receive(:post_json) do |_url, body:, **|
            bodies << body
            mock_response
          end
        end
      end

      it 'opens one MR per team plus a tooling MR (3 total)' do
        create_branch_and_mr

        expect(sync.workflow).to have_received(:post_json).exactly(3).times
      end

      it 'gives each team MR a slug-prefixed title and scoped content', :aggregate_failures do
        bodies = capture_all_bodies
        create_branch_and_mr
        titles = bodies.map { |b| b[:title] }

        # Titles are prefixed with the team_slug (never the @handle), so the
        # title itself never pings anyone.
        expect(titles).to include(
          a_string_starting_with('qa: '),
          a_string_starting_with('appsec: '),
          a_string_starting_with('tooling: ')
        )
        expect(titles).to all(satisfy { |t| !t.include?('@') })

        testing = bodies.find { |b| b[:title].start_with?('qa: ') }
        security = bodies.find { |b| b[:title].start_with?('appsec: ') }

        expect(testing[:description]).to include('#### `qa`')
        expect(testing[:description]).not_to include('#### `security`')
        expect(security[:description]).to include('#### `security`')
        expect(security[:description]).not_to include('#### `qa`')
      end

      it 'pushes a distinct per-team branch using each team slug', :aggregate_failures do
        today = Time.now.utc.strftime('%Y%m%d')
        pushed = []
        allow(sync).to receive(:system) do |*args, **|
          pushed << args.last if args.include?('push')
          true
        end
        create_branch_and_mr

        expect(pushed).to include(
          "docs-sync/principles-#{today}-qa:docs-sync/principles-#{today}-qa",
          "docs-sync/principles-#{today}-appsec:docs-sync/principles-#{today}-appsec",
          "docs-sync/principles-#{today}-tooling:docs-sync/principles-#{today}-tooling"
        )
      end
    end

    context 'when an MR has principles with secondary teams' do
      let(:distilled_contents) do
        { 'authentication' => "---\nsource_checksum: a\n---\n# Auth\n" }
      end

      let(:affected) do
        {
          'authentication' => {
            config: { 'sources' => [{ 'path' => 'doc/development/authentication.md' }] },
            changed_sources: [{ 'path' => 'doc/development/authentication.md' }], prior_sha: nil
          }
        }
      end

      before do
        sync.manifest.data = {
          'principles' => {
            'authentication' => {
              'owner_team' => '@a/authn', 'team_slug' => 'authentication',
              'secondary_teams' => ['@gitlab-com/gl-security/appsec'],
              'sources' => [{ 'path' => 'doc/development/authentication.md' }]
            }
          }
        }
      end

      it 'lists secondary teams as inline code (no bare mention) in a review section', :aggregate_failures do
        # Capture the team (non-tooling) MR body.
        captured = nil
        allow(sync.workflow).to receive(:post_json) do |_url, body:, **|
          captured = body unless body[:title].to_s.start_with?('tooling: ')
          mock_response
        end

        create_branch_and_mr

        expect(captured[:description]).to include('Request a review from')
        # Inline code, not a bare @mention, so the secondary group is not pinged.
        expect(captured[:description]).to include('`@gitlab-com/gl-security/appsec`')
        expect(captured[:description]).not_to match(/^- @gitlab-com/)
      end
    end

    context 'when the team opts out of pings (ping_team: false)' do
      let(:distilled_contents) do
        { 'backend-ruby' => "---\nsource_checksum: a\n---\n# Ruby\n" }
      end

      let(:affected) do
        {
          'backend-ruby' => {
            config: { 'sources' => [{ 'path' => 'doc/development/backend/ruby_style_guide.md' }] },
            changed_sources: [{ 'path' => 'doc/development/backend/ruby_style_guide.md' }], prior_sha: nil
          }
        }
      end

      before do
        sync.manifest.data = {
          'principles' => {
            'backend-ruby' => {
              'owner_team' => '@gitlab-org/maintainers/rails-backend', 'ping_team' => false,
              'sources' => [{ 'path' => 'doc/development/backend/ruby_style_guide.md' }]
            }
          }
        }
      end

      it 'uses the team_slug (not the @handle) in the title, commit, and summary', :aggregate_failures do
        captured = nil
        commits = []
        allow(sync.workflow).to receive(:post_json) do |_url, body:, **|
          captured = body unless body[:title].to_s.start_with?('tooling: ')
          mock_response
        end
        allow(sync).to receive(:commit_and_push) do |_branch, _pid, _tok, msg|
          commits << msg
        end

        create_branch_and_mr

        expect(captured[:title]).to start_with('rails-backend: ')
        expect(captured[:title]).not_to include('@')
        expect(captured[:description]).to include('**rails-backend**')
        expect(captured[:description]).not_to include('@gitlab-org/maintainers/rails-backend')
        expect(commits).to include(a_string_including('Update rails-backend AI development principles'))
      end
    end

    context 'with a long owner_team handle and several principles' do
      # A long owner_team handle plus several principles is the worst case for
      # both the subject (handle would overflow) and the body (Updated: list).
      let(:distilled_contents) do
        {
          'authentication' => "---\nsource_checksum: a\n---\n# Auth\n",
          'permissions-fundamentals' => "---\nsource_checksum: b\n---\n# Perms\n"
        }
      end

      let(:affected) do
        {
          'authentication' => { config: { 'sources' => [] }, changed_sources: [], prior_sha: nil },
          'permissions-fundamentals' => { config: { 'sources' => [] }, changed_sources: [], prior_sha: nil }
        }
      end

      let(:long_handle) { '@gitlab-org/software-supply-chain-security/authorization/approvers' }

      before do
        sync.manifest.data = {
          'principles' => {
            'authentication' => {
              'owner_team' => long_handle, 'team_slug' => 'authorization',
              'sources' => []
            },
            'permissions-fundamentals' => {
              'owner_team' => long_handle, 'team_slug' => 'authorization',
              'sources' => []
            }
          }
        }
      end

      it 'keeps every commit line within 72 chars and uses a slug subject + bullet body', :aggregate_failures do
        commits = []
        allow(sync).to receive(:commit_and_push).and_wrap_original do |_orig, *args|
          commits << args.last
          # Still exercise the guard, but skip the real git/push side effects.
          sync.send(:assert_commit_lines_within_limit!, args.last)
        end

        expect { create_branch_and_mr }.not_to raise_error

        team_commit = commits.find { |m| m.start_with?('Update authorization') }
        expect(team_commit).not_to be_nil
        expect(team_commit).to start_with('Update authorization AI development principles from SSOT')
        expect(team_commit).not_to include(long_handle)
        expect(team_commit).to include("Updated:\n- authentication\n- permissions-fundamentals")
        expect(team_commit.lines.map(&:chomp)).to all(satisfy { |l| l.length <= 72 })
      end
    end

    describe '#assert_commit_lines_within_limit!' do
      it 'raises when a non-URL line exceeds 72 characters' do
        msg = "Subject line ok\n\n#{'x' * 73}"

        expect { sync.send(:assert_commit_lines_within_limit!, msg) }
          .to raise_error(/over 72 chars/)
      end

      it 'allows long lines that contain a URL' do
        msg = "Subject line ok\n\nSee https://gitlab.com/#{'a' * 80}"

        expect { sync.send(:assert_commit_lines_within_limit!, msg) }.not_to raise_error
      end

      it 'passes when all lines are within the limit' do
        msg = "Update foo AI principles\n\nUpdated:\n- foo"

        expect { sync.send(:assert_commit_lines_within_limit!, msg) }.not_to raise_error
      end
    end

    context 'when the tooling files are already up to date' do
      before do
        # The team branch has staged principle changes; the tooling branch
        # does not. git_has_staged_changes? is consulted once per branch
        # (team first, then tooling).
        allow(sync).to receive(:git_has_staged_changes?).and_return(true, false)
      end

      it 'skips the tooling MR but still opens the team MR' do
        bodies = []
        allow(sync.workflow).to receive(:post_json) do |_url, body:, **|
          bodies << body
          mock_response
        end

        create_branch_and_mr

        # Exactly the team MR; the tooling MR is skipped (no staged changes).
        expect(bodies.map { |b| b[:title] }).to contain_exactly(a_string_starting_with('qa: '))
      end
    end

    context "when a team's principles are unchanged on re-run" do
      before do
        # No staged changes on the team branch (same-day re-run, identical
        # content); tooling branch does have changes.
        allow(sync).to receive(:git_has_staged_changes?).and_return(false, true)
      end

      it 'skips the team MR without recording a failure, still opening the tooling MR' do
        bodies = []
        allow(sync.workflow).to receive(:post_json) do |_url, body:, **|
          bodies << body
          mock_response
        end

        expect { create_branch_and_mr }.not_to raise_error
        expect(bodies.map { |b| b[:title] }).to contain_exactly(a_string_starting_with('tooling: '))
      end
    end

    context 'when no tooling files exist on disk' do
      before do
        # None of the TOOLING_PATHS were generated (e.g. AGENTS.md absent), so
        # `git add -f` would have no paths. The tooling MR must be skipped
        # rather than raising and recording a spurious failure.
        allow(File).to receive(:exist?).and_call_original
        described_class::Manifest::TOOLING_PATHS.each do |path|
          allow(File).to receive(:exist?).with(Gitlab::PrinciplesDistiller::Workspace.safe_join(path))
            .and_return(false)
        end
      end

      it 'skips the tooling MR without raising, still opening the team MR' do
        expect { create_branch_and_mr }.not_to raise_error
        expect(sync.workflow).to have_received(:post_json).once
      end

      it 'warns instead of failing silently when the base checkout fails' do
        allow(sync).to receive(:system).and_return(true)
        allow(sync).to receive(:system)
          .with('git', '-C', anything, 'checkout', 'master').and_return(false)

        expect { create_branch_and_mr }.to output(/checkout to master failed/).to_stderr
      end
    end

    context 'when a tooling path is beyond a symlink' do
      before do
        # Simulate `.agents/skills` being a symlink (-> .claude/skills): the
        # file exists but `git add` would reject it as "beyond a symbolic
        # link". stageable_tooling_path? must skip it, leaving the real
        # `.claude/...` copy to carry the change.
        agents_skill = Gitlab::PrinciplesDistiller::Workspace.safe_join(
          described_class::Manifest::AGENTS_SKILL_PATH
        )
        allow(File).to receive(:realpath).and_call_original
        allow(File).to receive(:realpath) do |arg|
          arg.to_s == File.dirname(agents_skill) ? '/elsewhere/.claude/skills/gitlab-coding-principles' : arg
        end
      end

      it 'still opens the tooling MR (the symlinked alias is skipped, not fatal)' do
        bodies = []
        allow(sync.workflow).to receive(:post_json) do |_url, body:, **|
          bodies << body
          mock_response
        end

        expect { create_branch_and_mr }.not_to raise_error
        expect(bodies.map { |b| b[:title] }).to include(a_string_starting_with('tooling: '))
      end
    end

    context 'with a stubbed per-principle diff' do
      before do
        allow(sync).to receive(:compute_principle_diff)
          .and_return(["diff --git a/doc/development/qa.md b/doc/development/qa.md\n+new\n", false])
      end

      it 'embeds per-principle diff sections in the MR description', :aggregate_failures do
        expect(received_body[:description]).to include('#### `qa`')
        expect(received_body[:description]).to include('doc/development/qa.md')
        expect(received_body[:description]).to include('SSOT diff since previous distillation')
        expect(received_body[:description]).to include('````diff')
      end
    end

    it 'links the manifest and the CI job YAML in the "How this works" section', :aggregate_failures do
      expect(received_body[:description]).to include(
        '[`.ai/principles/manifest.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/principles/manifest.yml)',
        '[scheduled CI job](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/sync-principles.gitlab-ci.yml)'
      )
    end

    context 'when CI_JOB_URL is set' do
      before do
        stub_const('ENV', {
          'GITLAB_API_TOKEN' => 'token', 'CI_PROJECT_ID' => 'gitlab-org/gitlab',
          'CI_DEFAULT_BRANCH' => 'master', 'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
          'CI_PROJECT_DIR' => '/tmp/workspace',
          'CI_JOB_URL' => 'https://gitlab.com/gitlab-org/gitlab/-/jobs/123'
        })
      end

      it 'links the generating CI job in the description' do
        expect(received_body[:description]).to include(
          'This MR was generated by https://gitlab.com/gitlab-org/gitlab/-/jobs/123'
        )
      end
    end

    it 'omits the generating-job line when CI_JOB_URL is unset' do
      expect(received_body[:description]).not_to include('This MR was generated by')
    end

    it 'does not leave runs of blank lines when CI_JOB_URL is unset' do
      expect(received_body[:description]).not_to match(/\n{3,}/)
    end

    context 'with a custom auto_mr_cfg' do
      let(:auto_mr_cfg) do
        {
          'branch_prefix' => 'docs-sync/principles',
          'title_template' => 'Custom title %{date}',
          'labels' => %w[label-a label-b],
          'remove_source_branch' => false
        }
      end

      it 'applies auto_mr_cfg values to the MR title (slug-prefixed), labels, and flag', :aggregate_failures do
        today = Time.now.utc.strftime('%Y%m%d')

        expect(received_body[:title]).to eq("qa: Custom title #{today}")
        expect(received_body[:labels]).to eq('label-a,label-b')
        expect(received_body[:remove_source_branch]).to be(false)
      end
    end

    describe 'git push token handling' do
      # Record every `system(env, 'git', ..., 'push', ...)` invocation the
      # publish flow makes, so assertions can inspect the first push's env
      # hash and URL without re-stubbing per example.
      let(:pushes) { [] }
      let(:first_push) do
        create_branch_and_mr
        pushes.first
      end

      before do
        allow(sync).to receive(:system) do |*args, **|
          if args.include?('push')
            pushes << {
              env: (args[0] if args[0].is_a?(Hash)),
              url: args.find { |a| a.is_a?(String) && a.start_with?('https://') }
            }
          end

          true
        end
      end

      context 'with no existing GIT_CONFIG_COUNT in the environment' do
        it 'passes a single host-scoped HTTP Basic Authorization header via env vars' do
          # 'b2F1dGgyOnRva2Vu' == Base64("oauth2:token").
          expect(first_push[:env]).to eq(
            'GIT_CONFIG_COUNT' => '1',
            'GIT_CONFIG_KEY_0' => 'http.https://gitlab.com.extraHeader',
            'GIT_CONFIG_VALUE_0' => 'Authorization: Basic b2F1dGgyOnRva2Vu'
          )
        end

        it 'does not embed the token in the push URL' do
          expect(first_push[:url]).to eq('https://gitlab.com/gitlab-org/gitlab.git')
        end

        it 'does not include the raw token in the header value' do
          expect(first_push[:env]['GIT_CONFIG_VALUE_0']).not_to include('token')
        end
      end

      context 'when the parent environment already injects GIT_CONFIG_* entries' do
        # Simulates a GitLab Runner that pre-populates `GIT_CONFIG_COUNT`/
        # `GIT_CONFIG_KEY_*`/`GIT_CONFIG_VALUE_*` from CI variables.
        before do
          stub_const('ENV', {
            'GITLAB_API_TOKEN' => 'token',
            'CI_PROJECT_ID' => 'gitlab-org/gitlab',
            'CI_DEFAULT_BRANCH' => 'master',
            'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
            'CI_PROJECT_DIR' => '/tmp/workspace',
            'GIT_CONFIG_COUNT' => '2',
            'GIT_CONFIG_KEY_0' => 'http.proxy',
            'GIT_CONFIG_VALUE_0' => 'http://proxy.example:8080',
            'GIT_CONFIG_KEY_1' => 'core.sshCommand',
            'GIT_CONFIG_VALUE_1' => 'ssh -i /secrets/id_rsa'
          })
        end

        it 'appends at the next index without clobbering the existing count' do
          expect(first_push[:env]).to eq(
            'GIT_CONFIG_COUNT' => '3',
            'GIT_CONFIG_KEY_2' => 'http.https://gitlab.com.extraHeader',
            'GIT_CONFIG_VALUE_2' => 'Authorization: Basic b2F1dGgyOnRva2Vu'
          )
        end
      end

      context 'when the API token is empty' do
        before do
          stub_const('ENV', {
            'GITLAB_API_TOKEN' => '',
            'CI_PROJECT_ID' => 'gitlab-org/gitlab',
            'CI_DEFAULT_BRANCH' => 'master',
            'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
            'CI_PROJECT_DIR' => '/tmp/workspace'
          })
        end

        it 'aborts rather than pushing without credentials' do
          expect { create_branch_and_mr }.to raise_error(SystemExit)
        end
      end
    end

    context 'when an MR submission fails mid-flow' do
      # Inject the failure at the REST POST. By this point the team branch has
      # been created+checked out+pushed, so the per-team rescue has real
      # cleanup to do. The run then aborts with the aggregate failure list
      # rather than continuing silently.
      before do
        allow(sync.workflow).to receive(:post_json).and_raise(StandardError, 'boom')
      end

      it 'aborts with the aggregate failure list (team + tooling)' do
        # Assert on the final aggregate abort line specifically (not just the
        # per-team warn, which also contains the owner handle), so the test fails if
        # the abort doesn't fire.
        expect { create_branch_and_mr }.to raise_error(SystemExit)
          .and output(/MR\(s\) failed:.*alexpooley/).to_stderr
      end

      it 'attempts to check out the base branch during per-team cleanup' do
        expect { create_branch_and_mr }.to raise_error(SystemExit)

        expect(sync).to have_received(:system)
          .with('git', '-C', anything, 'checkout', 'master').at_least(:once)
      end

      it 'attempts to delete the team branch during cleanup' do
        expect { create_branch_and_mr }.to raise_error(SystemExit)

        today = Time.now.utc.strftime('%Y%m%d')
        expect(sync).to have_received(:system)
          .with('git', '-C', anything, 'branch', '-D', "docs-sync/principles-#{today}-qa")
      end

      context 'when the cleanup checkout itself fails' do
        before do
          allow(sync).to receive(:system).and_return(true)
          allow(sync).to receive(:system)
            .with('git', '-C', anything, 'checkout', 'master').and_return(false)
        end

        it 'warns about the failed checkout and still aborts' do
          expect { create_branch_and_mr }.to raise_error(SystemExit)
            .and output(/checkout to master failed/).to_stderr
        end
      end

      context 'when the cleanup branch deletion itself fails' do
        before do
          allow(sync).to receive(:system).and_return(true)
          allow(sync).to receive(:system)
            .with('git', '-C', anything, 'branch', '-D', anything).and_return(false)
        end

        it 'warns about the failed branch deletion and still aborts' do
          expect { create_branch_and_mr }.to raise_error(SystemExit)
            .and output(/cleanup deletion of branch.+failed/).to_stderr
        end
      end
    end
  end

  # Coverage for the decoupled reconcile path: the working tree already holds
  # the fences regenerated by pure projection from merged master (done by
  # Sync#reconcile_duo_instructions), and this helper cuts a fresh branch off
  # origin/master, re-applies just the Duo file, and opens/updates a dedicated
  # reconcile MR carrying only that change.
  describe '.create_reconcile_mr_from_working_tree' do
    subject(:reconcile) { sync.create_reconcile_mr_from_working_tree(auto_mr_cfg, manifest) }

    let(:manifest) { sync.manifest }
    let(:duo_dir) { File.join(tmpdir, '.gitlab', 'duo') }
    let(:duo_path) { File.join(duo_dir, 'mr-review-instructions.yaml') }

    let(:auto_mr_cfg) do
      {
        'branch_prefix' => 'docs-sync/principles',
        'title_template' => 'Update AI development principles from SSOT (%{date})',
        'labels' => %w[ai-agent documentation type::maintenance],
        'remove_source_branch' => true
      }
    end

    let(:mock_response) do
      instance_double(Net::HTTPResponse, is_a?: true, body: '{"web_url":"https://gitlab.com/foo"}', code: '201')
    end

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(duo_dir)
      File.write(duo_path, "instructions:\n")

      stub_const('ENV', { 'GITLAB_API_TOKEN' => 'token', 'CI_PROJECT_ID' => 'gitlab-org/gitlab',
                          'CI_DEFAULT_BRANCH' => 'master', 'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
                          'CI_PROJECT_DIR' => tmpdir })

      allow(File).to receive(:realpath) { |arg| arg }
      allow(sync).to receive_messages(system: true, git_has_staged_changes?: true, find_open_mr_iid: nil)
      # The fences are projected AFTER the fresh branch is cut, so the manifest
      # regenerates against the branch's base. Default: a change is produced.
      allow(manifest).to receive(:generate_duo_review_instructions).and_return(true)
      allow(sync.workflow).to receive_messages(
        post_json: mock_response,
        gitlab_host: 'https://gitlab.com',
        catalog_project_path: 'gitlab-org/gitlab',
        default_branch: 'master'
      )
    end

    it 'opens a dedicated reconcile MR carrying only the fence update' do
      date = Time.now.utc.strftime('%Y%m%d')

      reconcile

      expect(sync.workflow).to have_received(:post_json)
        .with(a_string_including('/merge_requests'), hash_including(body: hash_including(
          title: a_string_starting_with('reconcile fences: '),
          source_branch: "docs-sync/principles-#{date}-reconcile-fences"
        )))
    end

    it 'projects the fences after cutting the fresh branch, then stages only the Duo file' do
      calls = []
      allow(sync).to receive(:checkout_fresh_branch) { |*_a| calls << :checkout }
      allow(manifest).to receive(:generate_duo_review_instructions) do
        calls << :project
        true
      end
      staged = []
      allow(sync).to receive(:system) do |*args, **_kwargs|
        prefix = ['git', '-C', Gitlab::PrinciplesDistiller::Workspace.path, 'add', '-f']
        staged.concat(args[5..]) if args[0, 5] == prefix
        true
      end

      reconcile

      # Projection must happen after the branch is cut so it reads the branch's
      # base ref (gitlab-org/gitlab#604890), and only the Duo file is staged.
      expect(calls).to eq(%i[checkout project])
      expect(staged).to eq([described_class::Manifest::DUO_REVIEW_INSTRUCTIONS_PATH])
    end

    context 'when the projection produces no change' do
      before do
        allow(manifest).to receive(:generate_duo_review_instructions).and_return(false)
      end

      it 'skips the reconcile MR without calling the API' do
        reconcile

        expect(sync.workflow).not_to have_received(:post_json)
      end
    end

    context 'when the fences already match master' do
      before do
        allow(sync).to receive(:git_has_staged_changes?).and_return(false)
      end

      it 'skips the reconcile MR without calling the API' do
        reconcile

        expect(sync.workflow).not_to have_received(:post_json)
      end
    end
  end

  describe '.publish_tooling_branch' do
    subject(:publish) do
      sync.publish_tooling_branch('master', 'gitlab-org/gitlab', 'token', '20260702', auto_mr_cfg)
    end

    let(:duo_dir) { File.join(tmpdir, '.gitlab', 'duo') }
    let(:duo_path) { File.join(duo_dir, 'mr-review-instructions.yaml') }

    let(:auto_mr_cfg) do
      {
        'branch_prefix' => 'docs-sync/principles',
        'title_template' => 'Update AI development principles from SSOT (%{date})',
        'labels' => %w[ai-agent documentation type::maintenance],
        'remove_source_branch' => true
      }
    end

    let(:mock_response) do
      instance_double(Net::HTTPResponse, is_a?: true, body: '{"web_url":"https://gitlab.com/foo"}', code: '201')
    end

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(duo_dir)

      # A Duo file exists in the workspace, but the tooling branch must never
      # touch it -- the reconcile job owns it.
      File.write(duo_path, <<~YAML)
        instructions:
          # >>> generated: documentation — gitlab-ai-principles-distiller (from .ai/principles/manifest.yml; do not edit)
          # distilled_at_sha: stalesha
          # source_checksum: stalesum
          - name: Documentation
            fileFilters:
              - "doc/**/*.md"
            instructions: |
              old body
          # <<< end generated: documentation
      YAML

      sync.manifest.data = {
        'principles' => {
          'documentation' => {
            'group' => 'Documentation',
            'file_filters' => ['doc/**/*.md'],
            'owner_team' => '@gitlab-org/technical-writing',
            'sources' => [{ 'path' => 'a.md', 'url' => 'https://docs.gitlab.com/a/' }]
          }
        }
      }

      stub_const('ENV', { 'GITLAB_API_TOKEN' => 'token', 'CI_PROJECT_ID' => 'gitlab-org/gitlab',
                          'CI_DEFAULT_BRANCH' => 'master', 'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
                          'CI_PROJECT_DIR' => tmpdir })

      allow(File).to receive(:realpath) { |arg| arg }
      allow(sync).to receive_messages(system: true, git_has_staged_changes?: true, find_open_mr_iid: nil)
      allow(sync.workflow).to receive_messages(
        post_json: mock_response,
        gitlab_host: 'https://gitlab.com',
        catalog_project_path: 'gitlab-org/gitlab',
        default_branch: 'master'
      )
    end

    it 'never regenerates or stages the Duo review-instructions file' do
      staged = []
      allow(sync).to receive(:system) do |*args, **_kwargs|
        prefix = ['git', '-C', Gitlab::PrinciplesDistiller::Workspace.path, 'add', '-f']
        staged.concat(args[5..]) if args[0, 5] == prefix
        true
      end

      publish

      expect(staged).not_to include(described_class::Manifest::DUO_REVIEW_INSTRUCTIONS_PATH)
      # The Duo file on disk is left untouched by the tooling branch.
      expect(File.read(duo_path)).to include('old body')
    end
  end

  describe '#push_with_retries' do
    subject(:push) { sync.send(:push_with_retries, env, push_url, branch) }

    let(:env) { { 'GIT_CONFIG_COUNT' => '1' } }
    let(:push_url) { 'https://gitlab.com/gitlab-org/gitlab.git' }
    let(:branch) { 'docs-sync/principles-20260703-tooling' }

    before do
      # Don't actually sleep between retries.
      allow(sync).to receive(:sleep)
    end

    context 'when the push succeeds on the first attempt' do
      before do
        allow(sync).to receive(:system).and_return(true)
      end

      it 'pushes exactly once and does not back off' do
        push

        expect(sync).to have_received(:system)
          .with(env, 'git', '-C', anything, 'push', '--force', push_url, "#{branch}:#{branch}", exception: true)
          .once
        expect(sync).not_to have_received(:sleep)
      end
    end

    context 'when the push fails transiently then succeeds' do
      before do
        # `system(..., exception: true)` raises on a non-zero git exit; the
        # first attempt raises, the second returns normally.
        call_count = 0
        allow(sync).to receive(:system) do
          call_count += 1
          raise 'the remote end hung up unexpectedly' if call_count == 1

          true
        end
      end

      it 'retries after a backoff and eventually succeeds', :aggregate_failures do
        expect { push }.not_to raise_error

        expect(sync).to have_received(:system).twice
        expect(sync).to have_received(:sleep).with(described_class::PUSH_RETRY_BACKOFF_SECONDS[0]).once
      end

      it 'warns about the transient failure before retrying' do
        expect { push }.to output(/push of #{Regexp.escape(branch)} failed .*retrying in/m).to_stderr
      end
    end

    context 'when the push keeps failing' do
      before do
        allow(sync).to receive(:system).and_raise('HTTP 502')
      end

      it 'retries up to PUSH_MAX_ATTEMPTS then re-raises the last error', :aggregate_failures do
        expect { push }.to raise_error(/HTTP 502/)

        expect(sync).to have_received(:system).exactly(described_class::PUSH_MAX_ATTEMPTS).times
        # One backoff between each pair of attempts: MAX_ATTEMPTS - 1 sleeps.
        expect(sync).to have_received(:sleep).exactly(described_class::PUSH_MAX_ATTEMPTS - 1).times
      end
    end
  end
end
