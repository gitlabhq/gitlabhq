# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../support/tmpdir'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::Manifest do
  include TmpdirHelper

  let(:tmpdir) { mktmpdir }
  let(:manifest) { described_class.new }

  describe 'TOOLING_PATHS' do
    it 'excludes the Duo review-instructions file (fences are reconciled separately)' do
      # The Duo fences are reconciled from merged-master content by the
      # scheduled reconcile job, not regenerated inside the distillation
      # tooling branch, so this file must NOT ride along in the tooling MR.
      expect(described_class::TOOLING_PATHS).not_to include(described_class::DUO_REVIEW_INSTRUCTIONS_PATH)
    end
  end

  describe '.load_frontmatter_data' do
    subject(:frontmatter_data) { manifest.load_frontmatter_data }

    let(:principles_dir) { File.join(tmpdir, 'principles') }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      stub_const("#{described_class}::PRINCIPLES_DIR", 'principles')
      FileUtils.mkdir_p(principles_dir)
    end

    context 'with file containing source_checksum frontmatter' do
      before do
        File.write(File.join(principles_dir, 'test.md'), "---\nsource_checksum: abc123\n---\n# Test")
      end

      it { is_expected.to eq({ 'test' => { checksum: 'abc123', distilled_at_sha: nil } }) }
    end

    context 'with file containing source_checksum and distilled_at_sha frontmatter' do
      before do
        File.write(File.join(principles_dir, 'test.md'),
          "---\nsource_checksum: abc123\ndistilled_at_sha: def456\n---\n# Test")
      end

      it { is_expected.to eq({ 'test' => { checksum: 'abc123', distilled_at_sha: 'def456' } }) }
    end

    context 'with file without frontmatter' do
      before do
        File.write(File.join(principles_dir, 'no-frontmatter.md'), '# No frontmatter here')
      end

      it { is_expected.to eq({}) }
    end

    context 'with file without source_checksum key' do
      before do
        File.write(File.join(principles_dir, 'other.md'), "---\nother_key: value\n---\n# Other")
      end

      it { is_expected.to eq({}) }
    end
  end

  describe '.load' do
    let(:manifest_dir) { File.join(tmpdir, '.ai', 'principles') }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(manifest_dir)
      File.write(File.join(manifest_dir, 'manifest.yml'), manifest_yaml)
    end

    context 'when every principle has sources and an owner_team' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            backend:
              owner_team: '@gitlab-org/maintainers/rails-backend'
              sources:
                - path: doc/backend.md
                  url: https://example.com/backend
            qa:
              owner_team: '@abdwdd @alexpooley'
              sources:
                - path: doc/qa.md
        YAML
      end

      it 'returns the parsed manifest without aborting' do
        expect { manifest.load }.not_to raise_error
      end
    end

    context 'when a principle is missing the sources key' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            backend:
              owner_team: '@gitlab-org/maintainers/rails-backend'
              sources:
                - path: doc/backend.md
            qa:
              owner_team: '@abdwdd @alexpooley'
              group: Testing
        YAML
      end

      it 'aborts and names the offending principle' do
        expect { manifest.load }
          .to raise_error(SystemExit)
          .and output(/qa/).to_stderr
      end
    end

    context 'when a principle has an empty sources array' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            backend:
              owner_team: '@gitlab-org/maintainers/rails-backend'
              sources: []
        YAML
      end

      it 'aborts and names the offending principle' do
        expect { manifest.load }
          .to raise_error(SystemExit)
          .and output(/backend/).to_stderr
      end
    end

    context 'when a principle is missing the owner_team key' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            backend:
              owner_team: '@gitlab-org/maintainers/rails-backend'
              sources:
                - path: doc/backend.md
            qa:
              sources:
                - path: doc/qa.md
        YAML
      end

      it 'aborts and names the offending principle' do
        expect { manifest.load }
          .to raise_error(SystemExit)
          .and output(/owner_team.*qa/m).to_stderr
      end
    end

    context 'when a principle has a blank owner_team' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            backend:
              owner_team: '   '
              sources:
                - path: doc/backend.md
        YAML
      end

      it 'aborts and names the offending principle' do
        expect { manifest.load }
          .to raise_error(SystemExit)
          .and output(/owner_team.*backend/m).to_stderr
      end
    end

    context 'when principles share an owner_team but declare conflicting team_slug values' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            authn:
              owner_team: '@org/ssc/approvers'
              team_slug: authentication
              sources:
                - path: doc/authn.md
            authz:
              owner_team: '@org/ssc/approvers'
              team_slug: authorization
              sources:
                - path: doc/authz.md
        YAML
      end

      it 'aborts naming the handle and the conflicting slugs', :aggregate_failures do
        expect { manifest.load }
          .to raise_error(SystemExit)
          .and output(%r{conflicting `team_slug:`.*@org/ssc/approvers}m).to_stderr
      end
    end

    context 'when principles share an owner_team and agree on team_slug' do
      let(:manifest_yaml) do
        <<~YAML
          principles:
            authz-a:
              owner_team: '@org/ssc/approvers'
              team_slug: authorization
              sources:
                - path: doc/a.md
            authz-b:
              owner_team: '@org/ssc/approvers'
              team_slug: authorization
              sources:
                - path: doc/b.md
        YAML
      end

      it 'does not abort' do
        expect { manifest.load }.not_to raise_error
      end
    end
  end

  describe '.source_file_exists?' do
    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
    end

    context 'when the file exists on disk' do
      before do
        FileUtils.mkdir_p(File.join(tmpdir, 'doc'))
        File.write(File.join(tmpdir, 'doc', 'backend.md'), 'content')
      end

      it { expect(manifest.source_file_exists?('doc/backend.md')).to be(true) }
    end

    context 'when the file was converted to a directory with an _index.md' do
      before do
        FileUtils.mkdir_p(File.join(tmpdir, 'doc', 'backend'))
        File.write(File.join(tmpdir, 'doc', 'backend', '_index.md'), 'content')
      end

      it 'resolves via the _index.md fallback' do
        expect(manifest.source_file_exists?('doc/backend.md')).to be(true)
      end
    end

    context 'when neither the file nor an _index.md exists' do
      it { expect(manifest.source_file_exists?('doc/missing.md')).to be(false) }
    end
  end

  describe '.missing_source_files' do
    subject(:missing) { manifest.missing_source_files }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(File.join(tmpdir, 'doc'))
      FileUtils.mkdir_p(File.join(tmpdir, '.ai'))
      manifest.data = manifest_data
    end

    let(:manifest_data) do
      {
        'principles' => {
          'backend' => {
            'baseline' => '.ai/principles/baselines/backend.md',
            'sources' => [
              { 'path' => 'doc/present.md' },
              { 'path' => 'doc/missing.md' }
            ]
          },
          'qa' => {
            'sources' => [{ 'path' => 'doc/present.md' }]
          }
        },
        'static_entries' => [
          { 'path' => '.ai/present-static.md' },
          { 'path' => '.ai/missing-static.md' }
        ]
      }
    end

    context 'when some referenced paths are missing' do
      before do
        File.write(File.join(tmpdir, 'doc', 'present.md'), 'content')
        File.write(File.join(tmpdir, '.ai', 'present-static.md'), 'content')
      end

      it 'returns the sorted, de-duplicated list of missing paths including baselines and static entries' do
        expect(missing).to eq(
          [
            '.ai/missing-static.md',
            '.ai/principles/baselines/backend.md',
            'doc/missing.md'
          ]
        )
      end

      it 'does not include a path that is shared by multiple principles and exists' do
        expect(missing).not_to include('doc/present.md')
      end

      it 'does not include a static entry that exists' do
        expect(missing).not_to include('.ai/present-static.md')
      end
    end

    context 'when every referenced path resolves on disk' do
      before do
        File.write(File.join(tmpdir, 'doc', 'present.md'), 'content')
        File.write(File.join(tmpdir, 'doc', 'missing.md'), 'content')
        File.write(File.join(tmpdir, '.ai', 'present-static.md'), 'content')
        File.write(File.join(tmpdir, '.ai', 'missing-static.md'), 'content')
        FileUtils.mkdir_p(File.join(tmpdir, '.ai', 'principles', 'baselines'))
        File.write(File.join(tmpdir, '.ai', 'principles', 'baselines', 'backend.md'), 'content')
      end

      it { is_expected.to be_empty }
    end
  end

  describe '.sources_footer' do
    subject(:footer) { manifest.sources_footer(config) }

    context 'with sources' do
      let(:config) do
        {
          'sources' => [
            { 'path' => 'doc/development/testing_guide/best_practices.md' },
            { 'path' => 'doc/development/testing_guide/testing_levels.md' }
          ]
        }
      end

      it 'lists source paths', :aggregate_failures do
        expect(footer).to include('## Authoritative sources')
        expect(footer).to include('- doc/development/testing_guide/best_practices.md')
        expect(footer).to include('- doc/development/testing_guide/testing_levels.md')
      end
    end

    context 'without sources' do
      let(:config) { { 'sources' => [] } }

      it { is_expected.to eq('') }
    end
  end

  describe '.generate_principles_skill' do
    let(:agents_skill_path) { File.join(tmpdir, '.agents/skills/gitlab-coding-principles/SKILL.md') }
    let(:claude_skill_path) { File.join(tmpdir, '.claude/skills/gitlab-coding-principles/SKILL.md') }
    let(:manifest_data) do
      {
        'principles' => {
          'backend' => { 'group' => 'Backend', 'description' => 'Backend Ruby/Rails',
                         'file_filters' => ['app/**/*.rb'] },
          'security' => { 'group' => 'Security', 'description' => 'Security vulnerabilities',
                          'file_filters' => ['**/*'] }
        },
        'static_entries' => []
      }
    end

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      manifest.data = manifest_data
      manifest.generate_principles_skill
    end

    it 'writes SKILL.md to both .agents/skills/ and .claude/skills/', :aggregate_failures do
      expect(File.exist?(agents_skill_path)).to be true
      expect(File.exist?(claude_skill_path)).to be true
    end

    it 'generates identical content in both locations' do
      expect(File.read(agents_skill_path)).to eq(File.read(claude_skill_path))
    end

    it 'includes YAML frontmatter with name and description', :aggregate_failures do
      content = File.read(claude_skill_path)

      expect(content).to include('name: gitlab-coding-principles')
      expect(content).to include('description: "MUST USE before planning, implementing, refactoring')
    end

    it 'includes principle entries from manifest', :aggregate_failures do
      content = File.read(claude_skill_path)

      expect(content).to include('Backend Ruby/Rails')
      expect(content).to include('Security vulnerabilities')
      expect(content).to include('.ai/principles/distilled/backend.md')
    end

    context 'when skill files are already up to date' do
      it 'does not rewrite them' do
        mtime_before = File.mtime(claude_skill_path)
        sleep 0.01
        manifest.data = manifest_data
        manifest.generate_principles_skill

        expect(File.mtime(claude_skill_path)).to eq(mtime_before)
      end
    end
  end

  describe '.extract_frontmatter' do
    subject(:extract_frontmatter) { manifest.extract_frontmatter(content) }

    context 'with YAML frontmatter' do
      let(:content) { "---\nsource_checksum: abc123\n---\n# Title\nBody" }

      it { is_expected.to eq({ 'source_checksum' => 'abc123' }) }
    end

    context 'without frontmatter' do
      let(:content) { '# Title\nBody' }

      it { is_expected.to be_nil }
    end

    context 'when content does not start with ---' do
      let(:content) { 'some text\n---\nmore' }

      it { is_expected.to be_nil }
    end
  end

  describe '.strip_frontmatter' do
    subject(:strip_frontmatter) { manifest.strip_frontmatter(content) }

    context 'with YAML frontmatter' do
      let(:content) { "---\nsource_checksum: abc123\n---\n# Title\nBody" }

      it { is_expected.to eq("# Title\nBody") }
    end

    context 'without frontmatter' do
      let(:content) { "# Title\nBody" }

      it { is_expected.to eq(content) }
    end

    context 'with leading whitespace after frontmatter' do
      let(:content) { "---\nkey: val\n---\n\n\n# Title" }

      it { is_expected.to eq('# Title') }
    end
  end

  describe '.compute_checksum' do
    subject(:checksum) { manifest.compute_checksum(config) }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
    end

    context 'with no sources' do
      let(:config) { { 'sources' => [] } }

      it { is_expected.to match(/\A[a-f0-9]{16}\z/) }
    end

    context 'when source content changes' do
      let(:config) { { 'sources' => [{ 'path' => 'doc.md' }] } }

      it 'changes the checksum' do
        source_path = File.join(tmpdir, 'doc.md')
        File.write(source_path, 'original content')

        checksum1 = checksum

        # Use a fresh Manifest (and therefore a fresh @file_cache) for the
        # second read; the cache is intentionally process-lived to avoid
        # duplicate I/O within one run, so in-test file mutations must
        # escape the cache via a new instance.
        File.write(source_path, 'modified content')
        expect(described_class.new.compute_checksum(config)).not_to eq(checksum1)
      end
    end

    context 'with a baseline file' do
      let(:config) { { 'sources' => [], 'baseline' => 'baseline.md' } }

      before do
        File.write(File.join(tmpdir, 'baseline.md'), 'baseline rules')
      end

      it 'includes baseline content in checksum' do
        checksum_without = manifest.compute_checksum({ 'sources' => [] })

        expect(checksum).not_to eq(checksum_without)
      end
    end

    context 'when description changes' do
      it 'changes the checksum' do
        with_desc_a = manifest.compute_checksum({ 'sources' => [], 'description' => 'A' })
        with_desc_b = manifest.compute_checksum({ 'sources' => [], 'description' => 'B' })

        expect(with_desc_a).not_to eq(with_desc_b)
      end
    end

    context 'when group changes' do
      it 'changes the checksum' do
        in_group_a = manifest.compute_checksum({ 'sources' => [], 'group' => 'Backend' })
        in_group_b = manifest.compute_checksum({ 'sources' => [], 'group' => 'Database' })

        expect(in_group_a).not_to eq(in_group_b)
      end
    end

    context 'when prerequisite flag changes' do
      it 'changes the checksum' do
        as_prereq = manifest.compute_checksum({ 'sources' => [], 'prerequisite' => true })
        not_prereq = manifest.compute_checksum({ 'sources' => [], 'prerequisite' => false })

        expect(as_prereq).not_to eq(not_prereq)
      end
    end

    context 'when file_filters change' do
      it 'changes the checksum' do
        with_filters_a = manifest.compute_checksum({ 'sources' => [], 'file_filters' => ['app/**/*.rb'] })
        with_filters_b = manifest.compute_checksum({ 'sources' => [], 'file_filters' => ['lib/**/*.rb'] })

        expect(with_filters_a).not_to eq(with_filters_b)
      end
    end
  end

  describe '.generate_agents_md_context_loading' do
    let(:manifest_data) do
      {
        'principles' => {
          'database-queries' => { 'description' => 'SQL performance', 'group' => 'Database' },
          'database-schema' => { 'description' => 'Column types', 'group' => 'Database' },
          'backend-ruby' => { 'description' => 'Ruby style', 'group' => 'Backend' }
        },
        'static_entries' => [
          { 'description' => 'Git conventions', 'path' => '.ai/git.md' }
        ]
      }
    end

    let(:agents_md_content) do
      <<~MD
        # GitLab Project Guidelines

        ## Context Loading

        <!-- BEGIN GENERATED: gitlab-ai-principles-distiller — do not edit manually -->
        ### OpenCode

        Old content that should be replaced.

        <!-- END GENERATED -->

        ### Claude Code

        Skip this section.
      MD
    end

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      File.write(File.join(tmpdir, 'AGENTS.md'), agents_md_content)
      File.write(File.join(tmpdir, 'CLAUDE.md'), agents_md_content)
    end

    it 'replaces the generated section with grouped principles' do
      manifest.data = manifest_data
      manifest.generate_agents_md_context_loading

      content = File.read(File.join(tmpdir, 'AGENTS.md'))

      expect(content).to include(
        '<!-- BEGIN GENERATED: gitlab-ai-principles-distiller — do not edit manually -->'
      )
      expect(content).to include('<!-- END GENERATED -->')
      expect(content).to include('**Database:**')
      expect(content).to include('**Backend:**')
      expect(content).to include('- **SQL performance**: Read .ai/principles/distilled/database-queries.md')
      expect(content).to include('- **Ruby style**: Read .ai/principles/distilled/backend-ruby.md')
      expect(content).to include('- **Git conventions**: Read .ai/git.md')
      expect(content).not_to include('Old content that should be replaced')
    end

    it 'preserves group order from first appearance in manifest' do
      manifest.data = manifest_data
      manifest.generate_agents_md_context_loading

      content = File.read(File.join(tmpdir, 'AGENTS.md'))
      database_pos = content.index('**Database:**')
      backend_pos = content.index('**Backend:**')

      expect(database_pos).to be < backend_pos
    end

    it 'keeps CLAUDE.md identical to AGENTS.md' do
      manifest.data = manifest_data
      manifest.generate_agents_md_context_loading

      expect(File.read(File.join(tmpdir, 'AGENTS.md')))
        .to eq(File.read(File.join(tmpdir, 'CLAUDE.md')))
    end

    it 'does nothing when AGENTS.md does not exist' do
      File.delete(File.join(tmpdir, 'AGENTS.md'))

      expect do
        manifest.data = manifest_data
        manifest.generate_agents_md_context_loading
      end.not_to raise_error
    end

    it 'does nothing when content is unchanged' do
      manifest.data = manifest_data
      manifest.generate_agents_md_context_loading
      mtime_before = File.mtime(File.join(tmpdir, 'AGENTS.md'))

      sleep(0.01)
      manifest.data = manifest_data
      manifest.generate_agents_md_context_loading
      mtime_after = File.mtime(File.join(tmpdir, 'AGENTS.md'))

      expect(mtime_after).to eq(mtime_before)
    end
  end

  describe '.build_diff_hint' do
    subject(:hint) { manifest.build_diff_hint(sha, source_paths) }

    let(:sha) { 'abc123def456' }

    context 'with simple paths' do
      let(:source_paths) { ['doc/development/sql.md', 'doc/development/database/query_performance.md'] }

      it 'produces a valid shelljoin git diff command' do
        expected = 'git diff abc123def456..HEAD -- ' \
          'doc/development/sql.md doc/development/database/query_performance.md'
        expect(hint).to eq(expected)
      end
    end

    context 'with a path containing spaces' do
      let(:source_paths) { ['doc/my dir/file.md'] }

      it 'shell-escapes the path so it is safe to copy-paste' do
        expect(hint).not_to include('doc/my dir/file.md')
      end
    end
  end

  describe '.read_repo_file (thread safety)' do
    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      File.write(File.join(tmpdir, 'shared.md'), 'content')
    end

    it 'returns the same content from all threads and caches it exactly once' do
      results = Array.new(10)
      threads = Array.new(10) do |i|
        Thread.new { results[i] = manifest.read_repo_file('shared.md') }
      end
      threads.each(&:join)

      expect(results).to all(eq('content'))
      expect(manifest.file_cache.keys).to eq(['shared.md'])
    end
  end

  describe '.auto_mr_config' do
    subject(:auto_mr_config) do
      manifest.data = manifest_data
      manifest.auto_mr_config
    end

    let(:full_cfg) do
      {
        'branch_prefix' => 'docs-sync/principles',
        'title_template' => 'Update AI development principles from SSOT (%{date})',
        'labels' => %w[ai-agent documentation type::maintenance],
        'remove_source_branch' => true
      }
    end

    context 'when all required keys are present' do
      let(:manifest_data) { { 'auto_mr' => full_cfg } }

      it 'returns the auto_mr block' do
        expect(auto_mr_config).to eq(full_cfg)
      end
    end

    context 'when the auto_mr block is missing entirely' do
      let(:manifest_data) { {} }

      it 'aborts' do
        expect { auto_mr_config }.to raise_error(SystemExit)
      end
    end

    context 'when the auto_mr block is not a hash' do
      let(:manifest_data) { { 'auto_mr' => 'invalid' } }

      it 'aborts' do
        expect { auto_mr_config }.to raise_error(SystemExit)
      end
    end

    context 'when a required key is missing' do
      let(:manifest_data) { { 'auto_mr' => full_cfg.except('labels') } }

      it 'aborts' do
        expect { auto_mr_config }.to raise_error(SystemExit)
      end
    end
  end

  describe '.principle_owner_team' do
    before do
      manifest.data = {
        'principles' => {
          'database' => { 'owner_team' => '@gitlab-org/maintainers/database' },
          'orphan' => {}
        }
      }
    end

    it 'returns the owner_team handle' do
      expect(manifest.principle_owner_team('database')).to eq('@gitlab-org/maintainers/database')
    end

    it 'returns nil when owner_team is absent' do
      expect(manifest.principle_owner_team('orphan')).to be_nil
    end
  end

  describe '.principle_secondary_teams' do
    before do
      manifest.data = {
        'principles' => {
          'authentication' => {
            'owner_team' => '@a/auth',
            'secondary_teams' => ['@gitlab-com/gl-security/appsec']
          },
          'database' => { 'owner_team' => '@gitlab-org/maintainers/database' }
        }
      }
    end

    it 'returns the secondary_teams list' do
      expect(manifest.principle_secondary_teams('authentication'))
        .to eq(['@gitlab-com/gl-security/appsec'])
    end

    it 'returns an empty array when none are declared' do
      expect(manifest.principle_secondary_teams('database')).to eq([])
    end
  end

  describe '.team_slug' do
    before do
      manifest.data = {
        'principles' => {
          'database' => { 'owner_team' => '@gitlab-org/maintainers/database' },
          'authn' => {
            'owner_team' => '@gitlab-org/software-supply-chain-security/authentication/approvers',
            'team_slug' => 'authentication'
          },
          'authz' => {
            'owner_team' => '@gitlab-org/software-supply-chain-security/authorization/approvers',
            'team_slug' => 'authorization'
          },
          'qa' => { 'owner_team' => '@abdwdd @alexpooley', 'team_slug' => 'qa' }
        }
      }
    end

    context 'when given a principle name' do
      it 'derives the slug from the owner_team handle last segment' do
        expect(manifest.team_slug('database')).to eq('database')
      end

      it 'prefers an explicit team_slug override' do
        expect(manifest.team_slug('authn')).to eq('authentication')
      end

      it 'uses the explicit slug for a multi-handle (individuals) owner_team' do
        expect(manifest.team_slug('qa')).to eq('qa')
      end
    end

    context 'when given an owner_team handle (the fan-out grouping key)' do
      it 'derives the slug from the handle last segment' do
        expect(manifest.team_slug('@gitlab-org/maintainers/database')).to eq('database')
      end

      it 'resolves an explicit team_slug declared by a principle owned by that handle',
        :aggregate_failures do
        # Both authentication and authorization end in "approvers"; without the
        # explicit override they would collide on the same branch slug.
        expect(manifest.team_slug('@gitlab-org/software-supply-chain-security/authentication/approvers'))
          .to eq('authentication')
        expect(manifest.team_slug('@gitlab-org/software-supply-chain-security/authorization/approvers'))
          .to eq('authorization')
      end
    end
  end

  describe '.principle_team' do
    before do
      manifest.data = {
        'principles' => {
          'qa' => { 'owner_team' => '@abdwdd @alexpooley', 'group' => 'Testing' },
          'orphan' => {}
        }
      }
    end

    it 'returns the owner_team handle (the grouping key, not the group label)' do
      expect(manifest.principle_team('qa')).to eq('@abdwdd @alexpooley')
    end

    it 'falls back to "Other" when no owner_team is set' do
      expect(manifest.principle_team('orphan')).to eq('Other')
    end
  end

  describe '.principle_ping_team?' do
    before do
      manifest.data = {
        'principles' => {
          'small' => { 'owner_team' => '@a/small' },
          'large' => { 'owner_team' => '@a/large', 'ping_team' => false }
        }
      }
    end

    it 'defaults to true when ping_team is absent' do
      expect(manifest.principle_ping_team?('small')).to be(true)
    end

    it 'returns false when ping_team is explicitly false' do
      expect(manifest.principle_ping_team?('large')).to be(false)
    end
  end

  describe '.team_pings? and .team_display' do
    before do
      manifest.data = {
        'principles' => {
          'be-a' => { 'owner_team' => '@gitlab-org/maintainers/rails-backend', 'ping_team' => false },
          'be-b' => { 'owner_team' => '@gitlab-org/maintainers/rails-backend', 'ping_team' => false },
          'db' => { 'owner_team' => '@gitlab-org/maintainers/database' },
          'mixed-a' => { 'owner_team' => '@a/mixed', 'ping_team' => false },
          'mixed-b' => { 'owner_team' => '@a/mixed' }
        }
      }
    end

    context 'when every principle owned by the handle opts out' do
      it 'does not ping and displays the team_slug', :aggregate_failures do
        expect(manifest.team_pings?('@gitlab-org/maintainers/rails-backend')).to be(false)
        expect(manifest.team_display('@gitlab-org/maintainers/rails-backend')).to eq('rails-backend')
      end
    end

    context 'when the handle has no opt-out' do
      it 'pings and displays the raw handle', :aggregate_failures do
        expect(manifest.team_pings?('@gitlab-org/maintainers/database')).to be(true)
        expect(manifest.team_display('@gitlab-org/maintainers/database'))
          .to eq('@gitlab-org/maintainers/database')
      end
    end

    context 'when only some principles owned by the handle opt out' do
      it 'still pings (any opt-in wins)', :aggregate_failures do
        expect(manifest.team_pings?('@a/mixed')).to be(true)
        expect(manifest.team_display('@a/mixed')).to eq('@a/mixed')
      end
    end
  end

  describe '.group_principles_by_team' do
    before do
      manifest.data = {
        'principles' => {
          'database-fundamentals' => { 'owner_team' => '@gitlab-org/maintainers/database' },
          'security' => { 'owner_team' => '@gitlab-com/gl-security/appsec' },
          'database-queries' => { 'owner_team' => '@gitlab-org/maintainers/database' },
          'orphan' => {}
        }
      }
    end

    it 'groups names by owner_team, preserving manifest declaration order' do
      result = manifest.group_principles_by_team(
        %w[security database-queries database-fundamentals orphan]
      )

      expect(result).to eq(
        '@gitlab-org/maintainers/database' => %w[database-fundamentals database-queries],
        '@gitlab-com/gl-security/appsec' => %w[security],
        'Other' => %w[orphan]
      )
    end

    it 'ignores names not present in the manifest' do
      result = manifest.group_principles_by_team(%w[security unknown-principle])

      expect(result).to eq('@gitlab-com/gl-security/appsec' => ['security'])
    end
  end

  describe '.generate_codeowners' do
    let(:codeowners_dir) { File.join(tmpdir, '.gitlab') }
    let(:codeowners_content) do
      <<~OWNERS
        /.agents/ @dgruzd @tkuah
        /.ai/ @dgruzd @tkuah
        /.claude/ @dgruzd @tkuah
      OWNERS
    end

    let(:codeowners_path) { File.join(codeowners_dir, 'CODEOWNERS') }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(codeowners_dir)
      File.write(codeowners_path, codeowners_content)

      manifest.data = {
        'principles' => {
          'security' => { 'owner_team' => '@gitlab-com/gl-security/appsec' },
          'authentication' => {
            'owner_team' => '@a/authn',
            'secondary_teams' => ['@gitlab-com/gl-security/appsec']
          },
          'qa-rspec' => { 'owner_team' => '@abdwdd @alexpooley' }
        }
      }
    end

    it 'inserts a managed block immediately after the /.ai/ rule', :aggregate_failures do
      manifest.generate_codeowners

      lines = File.read(codeowners_path).lines.map(&:chomp)
      ai_idx = lines.index('/.ai/ @dgruzd @tkuah')
      begin_idx = lines.index(described_class::CODEOWNERS_BEGIN)
      claude_idx = lines.index('/.claude/ @dgruzd @tkuah')

      expect(begin_idx).to eq(ai_idx + 1)
      expect(claude_idx).to be > lines.index(described_class::CODEOWNERS_END)
    end

    it 'emits one per-file rule per principle routing to its owner_team', :aggregate_failures do
      manifest.generate_codeowners

      content = File.read(codeowners_path)
      expect(content).to include(
        '/.ai/principles/distilled/security.md @gitlab-com/gl-security/appsec'
      )
      expect(content).to include(
        '/.ai/principles/distilled/qa-rspec.md @abdwdd @alexpooley'
      )
    end

    it 'appends secondary_teams after the primary owner on the same rule' do
      manifest.generate_codeowners

      expect(File.read(codeowners_path)).to include(
        '/.ai/principles/distilled/authentication.md @a/authn @gitlab-com/gl-security/appsec'
      )
    end

    it 'is idempotent: a second run does not change the file' do
      manifest.generate_codeowners
      first = File.read(codeowners_path)

      manifest.generate_codeowners

      expect(File.read(codeowners_path)).to eq(first)
    end

    it 'replaces an existing managed block rather than appending a new one' do
      manifest.generate_codeowners

      manifest.data['principles'].delete('qa-rspec')
      manifest.generate_codeowners

      content = File.read(codeowners_path)
      expect(content.scan(described_class::CODEOWNERS_BEGIN).size).to eq(1)
      expect(content).not_to include('/.ai/principles/distilled/qa-rspec.md')
    end

    context 'when CODEOWNERS has no /.ai/ anchor rule' do
      let(:codeowners_content) { "/.claude/ @dgruzd @tkuah\n" }

      it 'aborts rather than placing the block in an undefined location' do
        expect { manifest.generate_codeowners }
          .to raise_error(SystemExit)
          .and output(%r{no `/\.ai/` rule}).to_stderr
      end
    end

    context 'when CODEOWNERS is absent' do
      before do
        FileUtils.rm_f(codeowners_path)
      end

      it 'skips generation without raising' do
        expect { manifest.generate_codeowners }.not_to raise_error
      end
    end
  end

  describe '.extract_checklist_body' do
    it 'returns the section headers and bullets, dropping frontmatter and footer' do
      content = <<~MD
        ---
        source_checksum: abc
        ---
        <!-- Auto-generated -->

        # Title

        ## Checklist

        ### Voice and Tone

        - Write in US English.

        ## Authoritative sources

        - doc/development/documentation/styleguide/_index.md
      MD

      expect(manifest.extract_checklist_body(content)).to eq(
        "### Voice and Tone\n\n- Write in US English."
      )
    end

    it 'returns an empty string when there is no section header' do
      expect(manifest.extract_checklist_body("---\nx: y\n---\n# Title\n")).to eq('')
    end
  end

  describe '.build_duo_fences' do
    let(:principles_dir) { File.join(tmpdir, '.ai', 'principles', 'distilled') }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(principles_dir)
      File.write(File.join(principles_dir, 'documentation.md'), <<~MD)
        ---
        source_checksum: sum123
        distilled_at_sha: sha456
        ---
        # Documentation

        ### Voice and Tone

        - Write in US English.

        ## Authoritative sources

        - doc/development/documentation/styleguide/_index.md
      MD

      manifest.data = {
        'principles' => {
          'documentation' => {
            'group' => 'Documentation',
            'file_filters' => ['doc/**/*.md'],
            'sources' => [
              { 'path' => 'a.md', 'url' => 'https://docs.gitlab.com/a/' },
              { 'path' => 'b.md', 'url' => 'https://docs.gitlab.com/b/' }
            ]
          }
        }
      }
    end

    it 'assembles fence data from the distilled frontmatter and manifest config' do
      fences = manifest.build_duo_fences(['documentation'])

      expect(fences['documentation']).to eq(
        name: 'Documentation',
        file_filters: ['doc/**/*.md'],
        distilled_body: "### Voice and Tone\n\n- Write in US English.",
        distilled_at_sha: 'sha456',
        source_checksum: 'sum123',
        references: ['a.md', 'b.md']
      )
    end

    it 'skips a principle whose distilled file is missing' do
      expect(manifest.build_duo_fences(['nonexistent'])).to eq({})
    end

    it 'projects the fence purely from the committed on-disk distilled file' do
      # Reconciliation is a pure projection of merged master: the fence data
      # comes only from the committed distilled file's frontmatter and body,
      # never from any in-memory content.
      fences = manifest.build_duo_fences(['documentation'])

      expect(fences['documentation']).to include(
        distilled_at_sha: 'sha456',
        source_checksum: 'sum123'
      )
    end
  end

  describe '.generate_duo_review_instructions' do
    let(:duo_dir) { File.join(tmpdir, '.gitlab', 'duo') }
    let(:duo_path) { File.join(duo_dir, 'mr-review-instructions.yaml') }
    let(:principles_dir) { File.join(tmpdir, '.ai', 'principles', 'distilled') }

    let(:duo_content) do
      <<~YAML
        instructions:
          # >>> generated: documentation — gitlab-ai-principles-distiller (from .ai/principles/manifest.yml; do not edit)
          # distilled_at_sha: stale
          # source_checksum: stale
          - name: Documentation
            fileFilters:
              - "doc/**/*.md"
            instructions: |
              old body
          # <<< end generated: documentation
      YAML
    end

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(duo_dir)
      FileUtils.mkdir_p(principles_dir)
      File.write(duo_path, duo_content)
      File.write(File.join(principles_dir, 'documentation.md'), <<~MD)
        ---
        source_checksum: fresh
        distilled_at_sha: fresh
        ---
        # Documentation

        ### Voice and Tone

        - Write in US English.

        ## Authoritative sources

        - doc/development/documentation/styleguide/_index.md
      MD

      manifest.data = {
        'principles' => {
          'documentation' => {
            'group' => 'Documentation',
            'file_filters' => ['doc/**/*.md'],
            'sources' => [{ 'path' => 'a.md', 'url' => 'https://docs.gitlab.com/a/' }]
          }
        }
      }
    end

    it 'refreshes the fenced region from the distilled file and reports the change' do
      expect(manifest.generate_duo_review_instructions).to be(true)

      content = File.read(duo_path)
      expect(content).to include('  # distilled_at_sha: fresh')
      expect(content).to include('      - Write in US English.')
      expect(content).not_to include('old body')
    end

    it 'is idempotent and reports no change on the second run' do
      manifest.generate_duo_review_instructions
      first = File.read(duo_path)

      expect(manifest.generate_duo_review_instructions).to be(false)

      expect(File.read(duo_path)).to eq(first)
    end

    it 'skips generation without raising when the file is absent' do
      FileUtils.rm_f(duo_path)
      expect(manifest.generate_duo_review_instructions).to be(false)
    end

    it 'projects the fence purely from the committed distilled file (no overrides accepted)' do
      # The reconcile job derives fences only from merged-master content, so
      # the method takes no in-memory overrides and the fence mirrors the
      # committed distilled file's frontmatter.
      manifest.generate_duo_review_instructions

      content = File.read(duo_path)
      expect(content).to include('  # distilled_at_sha: fresh')
      expect(content).to include('      - Write in US English.')
      expect(content).not_to include('old body')
      # The on-disk distilled file is left untouched; only the fence changed.
      expect(File.read(File.join(principles_dir, 'documentation.md'))).to include('source_checksum: fresh')
    end
  end

  describe '.problematic_duo_review_instructions' do
    let(:duo_dir) { File.join(tmpdir, '.gitlab', 'duo') }
    let(:duo_path) { File.join(duo_dir, 'mr-review-instructions.yaml') }
    let(:principles_dir) { File.join(tmpdir, '.ai', 'principles', 'distilled') }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = tmpdir
      FileUtils.mkdir_p(duo_dir)
      FileUtils.mkdir_p(principles_dir)
      File.write(duo_path, <<~YAML)
        instructions:
          # >>> generated: documentation — gitlab-ai-principles-distiller (from .ai/principles/manifest.yml; do not edit)
          # distilled_at_sha: recorded
          # source_checksum: recorded
          - name: Documentation
            fileFilters:
              - "doc/**/*.md"
            instructions: |
              body
          # <<< end generated: documentation
      YAML

      manifest.data = {
        'principles' => {
          'documentation' => {
            'group' => 'Documentation',
            'file_filters' => ['doc/**/*.md'],
            'sources' => [{ 'path' => 'a.md', 'url' => 'https://docs.gitlab.com/a/' }]
          }
        }
      }
    end

    def write_distilled(sha:, checksum:)
      File.write(File.join(principles_dir, 'documentation.md'), <<~MD)
        ---
        source_checksum: #{checksum}
        distilled_at_sha: #{sha}
        ---
        ### Voice and Tone

        - x.

        ## Authoritative sources

        - a.md
      MD
    end

    it 'reports the principle under stale when the distilled file has drifted' do
      write_distilled(sha: 'newer', checksum: 'newer')

      result = manifest.problematic_duo_review_instructions
      expect(result.stale).to eq(['documentation'])
      expect(result.failing).to eq(['documentation'])
    end

    it 'reports nothing when the recorded directives match the distilled file' do
      write_distilled(sha: 'recorded', checksum: 'recorded')

      result = manifest.problematic_duo_review_instructions
      expect(result.failing).to eq([])
      expect(result.pending).to eq([])
      expect(result).to be_clean
    end

    it 'classifies a fence as pending (not failing) when it is seeded but not yet distilled' do
      # No distilled file written: the manifest entry exists but distillation
      # has not run, so the fence is a valid pending seed rather than an orphan.
      result = manifest.problematic_duo_review_instructions
      expect(result.pending).to eq(['documentation'])
      expect(result.orphaned).to eq([])
      expect(result.failing).to eq([])
    end

    it 'classifies a fence as orphaned (failing) when it has no manifest entry and no distilled file' do
      manifest.data = { 'principles' => {} }

      result = manifest.problematic_duo_review_instructions
      expect(result.orphaned).to eq(['documentation'])
      expect(result.pending).to eq([])
      expect(result.failing).to eq(['documentation'])
    end

    it 'returns an empty result when the file is absent' do
      FileUtils.rm_f(duo_path)

      result = manifest.problematic_duo_review_instructions
      expect(result.failing).to eq([])
      expect(result.pending).to eq([])
      expect(result).to be_clean
    end
  end
end
