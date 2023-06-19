# frozen_string_literal: true

require_relative "lib/gitlab/rspec/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-rspec"
  spec.version = Gitlab::Rspec::Version::VERSION
  spec.authors = ["group::tenant-scale"]
  spec.email = ["engineering@gitlab.com"]

  spec.summary = "GitLab's RSpec extensions"
  spec.description = "A set of useful helpers to configure RSpec with various stubs and CI configs."
  spec.homepage = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-rspec"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_dependency "rspec", "~> 3.0"
end
