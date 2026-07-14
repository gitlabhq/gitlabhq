# frozen_string_literal: true

# NOTE: Do not remove the parentheses from this require statement!
#       They are necessary so it doesn't match the regex in `scripts/run-fast-specs.sh`,
#       and make the "fast" portion of that suite run slow.
require('fast_spec_helper') # NOTE: Do not remove the parentheses from this require statement!

# per-test-coverage:trigger (see .gitlab/ci/per_test_coverage.gitlab-ci.yml)
# merges the rendered rspec and jest child pipeline configs into a single
# child pipeline through three included artifacts. GitLab replaces a top-level
# `stages:` list wholesale with the last included config's rather than unioning
# them, so when the two templates declare different stages the other suite's
# jobs reference a stage that no longer exists and the child pipeline fails to
# create with zero jobs. This guards the invariant that both templates declare
# the same stages.
RSpec.describe 'per-test coverage child pipeline templates', feature_category: :tooling do
  templates_dir = File.expand_path('../../.gitlab/ci/per_test_coverage', __dir__)
  rspec_template = File.join(templates_dir, 'child_pipeline_template.erb')
  jest_template = File.join(templates_dir, 'jest_child_pipeline_template.erb')

  def declared_stages(template_path)
    block = File.read(template_path)[/^stages:\n((?:[ \t]+- .*\n)+)/, 1]
    raise "no top-level stages: block found in #{template_path}" if block.nil?

    block.scan(/^[ \t]+- (.+)$/).flatten.map(&:strip)
  end

  it 'declare the stages the merged child pipeline needs', :aggregate_failures do
    # The merged child must expose every stage its jobs use: `test` for the
    # rspec shards and `test-frontend` for the jest shards. Pinning the list
    # means dropping one (even from both templates) fails here instead of
    # silently breaking a suite when the child pipeline is created.
    expected_stages = %w[test test-frontend]
    expect(declared_stages(rspec_template)).to eq(expected_stages)
    expect(declared_stages(jest_template)).to eq(expected_stages)
  end
end
