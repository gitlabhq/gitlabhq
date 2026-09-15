# frozen_string_literal: true

# NOTE: Do not remove the parentheses from this require statement!
#       They are necessary so it doesn't match the regex in `scripts/run-fast-specs.sh`,
#       and make the "fast" portion of that suite run slow.
require('fast_spec_helper') # NOTE: Do not remove the parentheses from this require statement!

RSpec.describe '.gitlab-ci.yml Ruby version variables', feature_category: :tooling do
  gitlab_ci = YAML.safe_load_file(
    File.expand_path('../../.gitlab-ci.yml', __dir__),
    aliases: true
  ).freeze

  versions = YAML.safe_load_file(
    File.expand_path('../../.gitlab/ci/version.yml', __dir__),
    aliases: true
  ).fetch('variables').freeze

  # A Ruby version bump must move OMNIBUS_GITLAB_CACHE_EDITION with it, or
  # omnibus builds run the new Ruby against the previous version's cache.
  %w[.default-ruby-variables .next-ruby-variables].each do |anchor_name|
    describe anchor_name do
      it 'has an OMNIBUS_GITLAB_CACHE_EDITION matching its Ruby version' do
        anchor = gitlab_ci.fetch(anchor_name)
        version_variable = anchor.fetch('RUBY_VERSION')[/\$\{(\w+)\}/, 1]
        ruby_version = versions.fetch(version_variable)
        major, minor = ruby_version.split('.')
        expected_edition = "GITLAB_RUBY#{major}_#{minor}"
        edition = anchor.fetch('OMNIBUS_GITLAB_CACHE_EDITION')

        expect(edition).to eq(expected_edition),
          "#{anchor_name} sets OMNIBUS_GITLAB_CACHE_EDITION to #{edition}, but #{version_variable} " \
            "is #{ruby_version}. Update the cache edition in the same MR that changes #{version_variable}."
      end
    end
  end
end
