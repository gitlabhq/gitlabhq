# frozen_string_literal: true

# NOTE: Do not remove the parentheses from this require statement!
#       They are necessary so it doesn't match the regex in `scripts/run-fast-specs.sh`,
#       and make the "fast" portion of that suite run slow.
require('fast_spec_helper') # NOTE: Do not remove the parentheses from this require statement!

PatternsList = Struct.new(:name, :patterns)

RSpec.describe '.gitlab/ci/rules.gitlab-ci.yml', feature_category: :tooling do
  config = YAML.safe_load_file(
    File.expand_path('../../.gitlab/ci/rules.gitlab-ci.yml', __dir__),
    aliases: true
  ).freeze

  context 'with changes' do
    config.each do |name, definition|
      next unless definition.is_a?(Hash) && definition['rules']

      definition['rules'].each do |rule|
        next unless rule.is_a?(Hash) && rule['changes']

        # See this for why we want to always have if
        # https://docs.gitlab.com/ee/development/pipelines/internals.html#avoid-force_gitlab_ci
        it "#{name} has corresponding if" do
          expect(rule).to include('if')
        end
      end
    end
  end

  describe '.review:rules:start-review-app-pipeline' do
    let(:base_rules) { config.dig('.review:rules:start-review-app-pipeline', 'rules') }

    context 'with .review:rules:review-stop' do
      let(:derived_rules) { config.dig('.review:rules:review-stop', 'rules') }

      it 'has the same rules as the base, but automatic jobs changed to manual' do
        base_rules.zip(derived_rules).each do |(base, derived)|
          # .review:rules:review-stop don't set variables
          base.delete('variables')
          base_with_manual_and_allowed_to_fail =
            # base can be an array when we're using !reference
            if base.is_a?(Array) || base['when'] == 'never'
              base
            else
              base.merge('when' => 'manual', 'allow_failure' => true)
            end

          expect(derived).to eq(base_with_manual_and_allowed_to_fail)
        end
      end
    end
  end

  shared_examples 'predictive is inverse of non-predictive' do
    context 'with derived rules' do
      it 'has the "when: never" in reverse compared to the base' do
        rules_pairs = base_rules.zip(derived_rules)

        cut_point = rules_pairs.each.with_index do |(base, derived), index|
          # exception: `.if-merge-request-labels-pipeline-expedite` should both be set to "never",
          #            because when we set this label on an MR, we don't want to run either jobs.
          if base['if'] == config['.if-merge-request-labels-pipeline-expedite']['if']
            expect(derived).to eq(base)
            expect(derived['when']).to eq('never')
            next
          end

          # exception: `.if-merge-request-not-approved` in the base should be `.if-merge-request-approved` in derived.
          #            The base wants to run when the MR is approved, and the derived wants to run if it's not approved,
          #            and both are specifying this with `when: never`.
          if base['if'] == config['.if-merge-request-not-approved']['if']
            expect(derived).to eq(base.merge(config['.if-merge-request-approved']))
            expect(derived['when']).to eq('never')

            # The following rules should match exactly, because after the
            # approval rules, the logic is flipped.
            break index
          end

          if base['when'] == 'never'
            expect(derived).to eq(base.except('when'))
          elsif base['if'].start_with?('$ENABLE_')
            derived_if = base['if'].sub('RSPEC', 'RSPEC_PREDICTIVE_TRIGGER')
            expect(derived).to eq(base.merge('if' => derived_if))
          elsif base['when'].nil?
            expect(derived).to eq(base.merge('when' => 'never'))
          end
        end

        # Match the remaining rules that should be the same
        rules_pairs.drop(cut_point + 1).each do |(base, derived)|
          expect(derived).to eq(base)
        end
      end
    end
  end

  describe '.rails:rules:ee-and-foss-default-rules' do
    it_behaves_like 'predictive is inverse of non-predictive' do
      let(:base_rules) { config.dig('.rails:rules:ee-and-foss-default-rules', 'rules') }

      let(:derived_rules) do
        config.dig('.rails:rules:rspec-predictive', 'rules').reject do |rule|
          # This happens in each specific rspec,
          # which is outside of .rails:rules:ee-and-foss-default-rules
          rule['if'].start_with?('$ENABLE_')
        end
      end

      it 'contains an additional allow rule about code-backstage-patterns not present in the base' do
        expected_rule = {
          'if' => config['.if-merge-request']['if'],
          'changes' => config['.code-backstage-patterns']
        }

        expect(base_rules).not_to include(expected_rule)
        expect(derived_rules).to include(expected_rule)
      end
    end
  end

  describe '.rails:rules:single-db' do
    it_behaves_like 'predictive is inverse of non-predictive' do
      let(:base_rules) { config.dig('.rails:rules:single-db', 'rules') }
      let(:derived_rules) { config.dig('.rails:rules:rspec-predictive:single-db', 'rules') }
    end
  end

  describe '.rails:rules:single-db-ci-connection' do
    it_behaves_like 'predictive is inverse of non-predictive' do
      let(:base_rules) { config.dig('.rails:rules:single-db-ci-connection', 'rules') }
      let(:derived_rules) { config.dig('.rails:rules:rspec-predictive:single-db-ci-connection', 'rules') }
    end
  end

  describe 'start-as-if-foss' do
    let(:base_rules) { config.dig('.as-if-foss:rules:start-as-if-foss', 'rules') }

    context 'with .as-if-foss:rules:start-as-if-foss:allow-failure:manual' do
      let(:derived_rules) { config.dig('.as-if-foss:rules:start-as-if-foss:allow-failure:manual', 'rules') }

      it 'has the same rules as the base and also allow-failure and manual' do
        base_rules.zip(derived_rules).each do |(base, derived)|
          # !references should be the same. Stop rules should be the same.
          if base.is_a?(Array) || base['when'] == 'never'
            expect(base).to eq(derived)
          else
            expect(derived).to eq(
              base.merge('allow_failure' => true, 'when' => 'manual'))
          end
        end
      end
    end

    context 'with .as-if-foss:rules:start-as-if-foss:allow-failure' do
      let(:derived_rules) { config.dig('.as-if-foss:rules:start-as-if-foss:allow-failure', 'rules') }

      it 'has the same rules as the base and also allow-failure' do
        base_rules.zip(derived_rules).each do |(base, derived)|
          # !references should be the same. Stop rules should be the same.
          if base.is_a?(Array) || base['when'] == 'never'
            expect(base).to eq(derived)
          else
            expect(derived).to eq(base.merge('allow_failure' => true))
          end
        end
      end
    end
  end

  describe 'patterns' do
    foss_context = !Gitlab.ee?
    no_matching_needed_files = (
      [
        '.byebug_history',
        '.editorconfig',
        '.eslintcache',
        '.git-blame-ignore-revs',
        '.gitlab_kas_secret',
        '.gitlab_shell_secret',
        '.gitlab_workhorse_secret',
        '.gitlab/agents/review-apps/config.yaml',
        '.gitlab/changelog_config.yml',
        '.gitlab/CODEOWNERS',
        '.gitleaksignore',
        '.gitpod.yml',
        '.graphqlrc',
        '.index.yml.example',
        '.license_encryption_key.pub',
        '.mailmap',
        '.prettierignore',
        '.projections.json.example',
        '.solargraph.yml.example',
        '.solargraph.yml',
        '.test_license_encryption_key.pub',
        '.vale.ini',
        '.vscode/extensions.json',
        'ee/lib/ee/gitlab/background_migration/.rubocop.yml',
        'ee/LICENSE',
        'Gemfile.checksum',
        'Gemfile.next.checksum',
        'gems/error_tracking_open_api/.openapi-generator/FILES',
        'gems/error_tracking_open_api/.openapi-generator/VERSION',
        'gems/openbao_client/.openapi-generator/FILES',
        'gems/openbao_client/.openapi-generator/VERSION',
        'Guardfile',
        'INSTALLATION_TYPE',
        'lib/gitlab/background_migration/.rubocop.yml',
        'lib/gitlab/ci/templates/.yamllint',
        'LICENSE',
        'Pipfile.lock',
        'storybook/.env.template',
        'yarn-error.log'
      ] +
      Dir.glob('.bundle/**/*') +
      Dir.glob('.github/*') +
      Dir.glob('.gitlab/{issue,merge_request}_templates/**/*') +
      Dir.glob('.gitlab/*.toml') +
      Dir.glob('{,**/}.{DS_Store,gitignore,gitkeep,keep}', File::FNM_DOTMATCH) +
      Dir.glob('{,vendor/}gems/*/.*') +
      Dir.glob('{.git,.lefthook,.ruby-lsp}/**/*') +
      Dir.glob('{file_hooks,log}/**/*') +
      Dir.glob('{metrics_server,sidekiq_cluster}/*') +
      Dir.glob('{{,ee/}spec/fixtures,tmp}/**/*', File::FNM_DOTMATCH) +
      Dir.glob('*.md') +
      Dir.glob('changelogs/*') +
      Dir.glob('doc/.{markdownlint,vale}/**/*', File::FNM_DOTMATCH) +
      Dir.glob('node_modules/**/*', File::FNM_DOTMATCH) +
      Dir.glob('patches/*') +
      Dir.glob('public/assets/**/.*') +
      Dir.glob('qa/{,**/}.*') +
      Dir.glob('qa/.{,**/}*') +
      Dir.glob('qa/**/.gitlab-ci.yml') +
      Dir.glob('shared/**/*') +
      Dir.glob('workhorse/.*')
    ).freeze
    no_matching_needed_files_ci_specific = (
      [
        'metrics.txt'
      ] +
      Dir.glob('{auto_explain,crystalball,knapsack,rspec}/**/*') +
      Dir.glob('coverage/**/*', File::FNM_DOTMATCH) +
      Dir.glob('vendor/ruby/**/*', File::FNM_DOTMATCH)
    ).freeze
    all_files = Dir.glob('{,**/}*', File::FNM_DOTMATCH) -
      no_matching_needed_files -
      no_matching_needed_files_ci_specific
    all_files -= Dir.glob('ee/**/*', File::FNM_DOTMATCH) if foss_context
    all_files.reject! { |f| File.directory?(f) }

    # One loop to construct an array of PatternsList objects
    patterns_lists = config.filter_map do |name, patterns|
      next unless name.start_with?('.')
      next unless name.end_with?('patterns')

      # Ignore EE-only patterns list when in FOSS context
      relevant_patterns = if foss_context
                            patterns.reject do |pattern|
                              pattern =~ %r|^{?ee/| || pattern == '.tool-versions'
                            end
                          else
                            patterns
                          end

      next if relevant_patterns.empty?
      next if foss_context && name == '.custom-roles-patterns'

      PatternsList.new(name, relevant_patterns)
    end

    # One loop to gather a { pattern => files } hash
    patterns_files = patterns_lists.each_with_object({}) do |patterns_list, memo|
      patterns_list.patterns.each do |pattern|
        memo[pattern] ||= Dir.glob(pattern)
      end
    end

    # Example: '.ci-patterns': [".gitlab-ci.yml", ".gitlab/ci/**/*", "scripts/rspec_helpers.sh"]
    patterns_lists.each do |patterns_list|
      describe "patterns list `#{patterns_list.name}`" do
        patterns_list.patterns.each do |pattern|
          pattern_files = patterns_files.fetch(pattern)

          context "with `#{pattern}`" do
            it 'matches' do
              matching_files = (all_files & pattern_files)

              expect(matching_files).not_to be_empty
            end
          end
        end
      end
    end

    describe 'missed matched files' do
      all_matching_files = Set.new

      patterns_files.each_value do |files|
        all_matching_files.merge(files)
      end

      it 'does not miss files to match' do
        expect(all_files - all_matching_files.to_a).to be_empty
      end
    end
  end
end
