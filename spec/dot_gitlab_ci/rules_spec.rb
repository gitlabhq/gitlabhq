# frozen_string_literal: true

# NOTE: Do not remove the parentheses from this require statement!
#       They are necessary so it doesn't match the regex in `scripts/run-fast-specs.sh`,
#       and make the "fast" portion of that suite run slow.
require('fast_spec_helper') # NOTE: Do not remove the parentheses from this require statement!

PatternsList = Struct.new(:name, :patterns)

RSpec.describe '.gitlab/ci/rules.gitlab-ci.yml', :unlimited_max_formatted_output_length, feature_category: :tooling do
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

  describe 'anchor references' do
    rules_file_path = File.expand_path('../../.gitlab/ci/rules.gitlab-ci.yml', __dir__)
    raw_content = File.read(rules_file_path)

    anchor_definitions = raw_content.scan(/&([a-z][a-z0-9_-]*)/i).flatten.to_set

    # Match patterns like `<<: *anchor`, `- *anchor`, or `key: *anchor`
    anchor_references = Set.new
    raw_content.each_line do |line|
      next if line.strip.start_with?('#') # skip comments

      line.scan(/<<:\s*\*([a-z][a-z0-9_-]*)/i) { |m| anchor_references.add(m[0]) }

      line.scan(/^\s*-\s*\*([a-z][a-z0-9_-]*)/i) { |m| anchor_references.add(m[0]) }

      line.scan(/^\s*[a-z_-]+:\s*\*([a-z][a-z0-9_-]*)/i) { |m| anchor_references.add(m[0]) }
    end

    it 'has definitions for all anchor references' do
      undefined_anchors = anchor_references - anchor_definitions

      expect(undefined_anchors).to be_empty,
        "The following anchors are referenced but not defined: #{undefined_anchors.to_a.sort.join(', ')}"
    end

    it 'has no duplicate anchor definitions' do
      # Each anchor should be defined only once
      all_anchors = raw_content.scan(/&([a-z][a-z0-9_-]*)/i).flatten
      duplicates = all_anchors.group_by(&:itself).select { |_, v| v.size > 1 }.keys

      expect(duplicates).to be_empty,
        "The following anchors are defined multiple times: #{duplicates.sort.join(', ')}"
    end
  end

  describe 'rule structure' do
    valid_when_values = %w[always never on_success on_failure manual delayed].freeze

    it 'has valid when values in all rules' do
      invalid_rules = []

      config.each do |name, definition|
        next unless definition.is_a?(Hash) && definition['rules']

        definition['rules'].each_with_index do |rule, index|
          next unless rule.is_a?(Hash) && rule['when']
          next if valid_when_values.include?(rule['when'])

          invalid_rules << "#{name} rule[#{index}] has invalid when: #{rule['when']}"
        end
      end

      expect(invalid_rules).to be_empty, invalid_rules.join("\n")
    end

    it 'expedite label rules have when: never' do
      expedite_condition = config['.if-merge-request-labels-pipeline-expedite']['if']
      violations = []

      config.each do |name, definition|
        next unless definition.is_a?(Hash) && definition['rules']

        definition['rules'].each_with_index do |rule, index|
          next unless rule.is_a?(Hash)
          next unless rule['if'] == expedite_condition

          unless rule['when'] == 'never'
            violations << "#{name} rule[#{index}] uses expedite label but when is '#{rule['when']}' (expected 'never')"
          end
        end
      end

      expect(violations).to be_empty, violations.join("\n")
    end
  end

  describe 'naming conventions' do
    it 'all top-level keys start with .' do
      invalid_keys = config.keys.reject { |key| key.start_with?('.') }

      expect(invalid_keys).to be_empty,
        "Top-level keys should start with '.': #{invalid_keys.join(', ')}"
    end

    it 'if-conditions follow naming convention' do
      if_condition_keys = config.keys.select do |key|
        definition = config[key]
        definition.is_a?(Hash) && definition.key?('if') && !definition.key?('rules')
      end

      invalid_if_keys = if_condition_keys.reject { |key| key.start_with?('.if-') }

      expect(invalid_if_keys).to be_empty,
        "if-condition keys should start with '.if-': #{invalid_if_keys.join(', ')}"
    end
  end

  describe 'patterns' do
    foss_context = !Gitlab.ee?
    no_matching_needed_files = (
      [
        '.byebug_history',
        '.devfile.yaml',
        '.devfile/ci_runner.yaml',
        '.devfile/search.yaml',
        '.editorconfig',
        '.eslintcache',
        '.git-blame-ignore-revs',
        '.gitlab_kas_secret',
        '.gitlab_shell_secret',
        '.gitlab_workhorse_secret',
        '.gitlab_suggested_reviewers_secret',
        '.gitlab/changelog_config.yml',
        '.gitlab/CODEOWNERS',
        '.gitlab/lint/unused_methods/excluded_methods.yml',
        '.gitlab/lint/unused_methods/potential_methods_to_remove.yml',
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
        '.vscode/tasks.json',
        'ee/frontend_islands/apps/duo_next/.vscode/extensions.json',
        'ee/frontend_islands/apps/duo_next/.prettierignore',
        'ee/lib/ee/gitlab/background_migration/.rubocop.yml',
        'ee/LICENSE',
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
        'storybook/.babelrc.json',
        'yarn-error.log'
      ] +
      Dir.glob('.claude/**/*') +
      Dir.glob('.bundle/**/*') +
      Dir.glob('.github/*') +
      Dir.glob('.gitlab/duo/**/*') +
      Dir.glob('.gitlab/{issue,merge_request}_templates/**/*') +
      Dir.glob('.gitlab/*.toml') +
      Dir.glob('{,**/}.{DS_Store,gitignore,gitkeep,keep}', File::FNM_DOTMATCH) +
      Dir.glob('{,vendor/}gems/*/.*') +
      Dir.glob('{.git,.lefthook,.ruby-lsp}/**/*') +
      Dir.glob('{file_hooks,log}/**/*') +
      Dir.glob('{metrics_server,sidekiq_cluster}/*') +
      Dir.glob('{{,ee/}spec/fixtures,tmp}/**/*', File::FNM_DOTMATCH) +
      Dir.glob('*.md') +
      Dir.glob('ee/frontend_islands/**/*.md') +
      Dir.glob('public/assets/vite/.vite/**/*') +
      Dir.glob('changelogs/*') +
      Dir.glob('**/node_modules/**/*', File::FNM_DOTMATCH) +
      Dir.glob('patches/*') +
      Dir.glob('public/assets/**/.*') +
      Dir.glob('qa/{,**/}.*') +
      Dir.glob('qa/.{,**/}*') +
      Dir.glob('qa/**/.gitlab-ci.yml') +
      Dir.glob('shared/**/*') +
      Dir.glob('workhorse/.*') +
      Dir.glob('.idea/**/*', File::FNM_DOTMATCH) +
      Dir.glob('.yarn-cache/**/*', File::FNM_DOTMATCH)
    ).freeze
    no_matching_needed_files_ci_specific = (
      [
        'metrics.txt'
      ] +
      Dir.glob('{auto_explain,crystalball,knapsack,rspec}/**/*') +
      Dir.glob('coverage/**/*', File::FNM_DOTMATCH) +
      Dir.glob('coverage-frontend/**/*', File::FNM_DOTMATCH) +
      Dir.glob('ee/frontend_islands/apps/**/coverage/**/*', File::FNM_DOTMATCH) +
      Dir.glob('vendor/ruby/**/*', File::FNM_DOTMATCH) +
      Dir.glob('builds/**/*', File::FNM_DOTMATCH)
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

      it 'does not miss files to match',
        quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/11473' do
        expect(all_files - all_matching_files.to_a).to be_empty
      end
    end
  end
end
