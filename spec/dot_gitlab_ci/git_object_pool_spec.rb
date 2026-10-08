# frozen_string_literal: true

# NOTE: Do not remove the parentheses from this require statement!
#       They are necessary so it doesn't match the regex in `scripts/run-fast-specs.sh`,
#       and make the "fast" portion of that suite run slow.
require('fast_spec_helper') # NOTE: Do not remove the parentheses from this require statement!

# Guards the per-VM git object pool set up by the `pre_get_sources_script` hook in `default:`.
RSpec.describe 'CI per-VM git object pool', feature_category: :tooling do
  root = File.expand_path('../..', __dir__)
  # `!reference [a, b]` tags are not registered here, so they load as plain arrays (`["a", "b"]`).
  load_config = ->(path) { YAML.safe_load_file(path, aliases: true) }

  # The *.yml glob skips .erb templates, which are not valid YAML until rendered.
  ci_files = [File.join(root, '.gitlab-ci.yml')] + Dir.glob(File.join(root, '.gitlab/ci/**/*.yml'))
  jobs = ci_files.flat_map do |path|
    config = load_config.call(path)
    next [] unless config.is_a?(Hash)

    relative_path = path.delete_prefix("#{root}/")
    config.filter_map { |name, job| ["#{relative_path}: #{name}", job] if job.is_a?(Hash) }
  end.freeze

  gitlab_ci = load_config.call(File.join(root, '.gitlab-ci.yml')).freeze
  default_hooks = gitlab_ci.dig('default', 'hooks')
  default_seed_steps = default_hooks['pre_get_sources_script']
  # The hook seeds `$GLCI_GIT_OBJECT_POOL_DIR<path>`; capture `<path>` to check the
  # variable git borrows through names the same pool.
  pool_path = default_seed_steps.join("\n")[/\bglci_pool="\$GLCI_GIT_OBJECT_POOL_DIR([^"]+)"/, 1]

  # CI YAML `hooks:` only supports `pre_get_sources_script`. `post_get_sources_script` exists
  # only in the runner's config.toml, and GitLab rejects a pipeline that sets it here.
  it 'only uses hook keys that CI YAML supports' do
    expect(default_hooks.keys).to contain_exactly('pre_get_sources_script')
  end

  # Runners serve many projects, so they only say where pools live; the pool's name, and the
  # alternate git borrows through, belong to this project.
  it 'borrows from the pool the hook seeds' do
    expect(pool_path).to eq('$CI_PROJECT_DIR/.git')
    expect(gitlab_ci.dig('variables', 'GIT_ALTERNATE_OBJECT_DIRECTORIES'))
      .to eq('${GLCI_GIT_OBJECT_POOL_DIR}${CI_PROJECT_DIR}/.git/objects')
  end

  # The pool is an alternate object store, which `git fetch` reads, so none of this needs
  # native `git clone`. Switching the fleet onto it would also resolve the mutable MR merge
  # ref rather than refs/pipelines/<id>: gitlab-org/gitlab-runner#39641.
  it 'leaves the clone strategy to the runner' do
    expect(gitlab_ci['variables'])
      .not_to include('FF_USE_GIT_NATIVE_CLONE', 'FF_USE_GIT_BUNDLE_URIS', 'GIT_CLONE_EXTRA_FLAGS')
  end

  it 'keeps the default pre_get_sources_script steps in every job that overrides hooks' do
    references_default = ->(value, *path) { value == ['default', 'hooks', *path] }

    offenders = jobs.filter_map do |name, job|
      hooks = job['hooks']
      next if hooks.nil? || name == '.gitlab-ci.yml: default' || references_default.call(hooks)

      value = hooks.is_a?(Hash) ? hooks['pre_get_sources_script'] : nil
      next if references_default.call(value, 'pre_get_sources_script')

      steps = Array(value)
      next if steps.any? { |step| references_default.call(step, 'pre_get_sources_script') }

      name unless (default_seed_steps - steps).empty?
    end

    expect(offenders).to be_empty,
      "These jobs override `hooks` without the `pre_get_sources_script` steps from `default:` " \
        "(job-level hooks replace them): #{offenders.join(', ')}"
  end

  it 'never uploads a .git that borrows objects from the object pool' do
    global_strategy = gitlab_ci.dig('variables', 'GIT_STRATEGY')
    repo_root_paths = %w[* . ./ .git]
    no_source_strategies = %w[none empty]

    offenders = jobs.filter_map do |name, job|
      paths = Array(job.dig('artifacts', 'paths')).map(&:to_s)
      next unless paths.any? { |path| repo_root_paths.include?(path) || path.start_with?('.git/') }

      variables = job['variables'] || {}
      next if no_source_strategies.include?(variables.fetch('GIT_STRATEGY', global_strategy))

      name unless variables['GIT_ALTERNATE_OBJECT_DIRECTORIES'] == ''
    end

    expect(offenders).to be_empty,
      "These jobs upload .git as an artifact and must set GIT_ALTERNATE_OBJECT_DIRECTORIES " \
        "to \"\": #{offenders.join(', ')}"
  end
end
