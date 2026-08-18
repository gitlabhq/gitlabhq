# frozen_string_literal: true

require 'fileutils'

# Shared setup helpers for Ruby Pact consumer specs.
module PactHelper
  # Derives the contract output directory from the spec file's own location
  # and ensures it exists.
  #
  # The directory is resolved by mirroring the service segment of the spec
  # path under spec/contracts/contracts/external/, matching the GCS bucket
  # layout: <bucket>/<service-slug>/<version>/<contract>.json
  #
  # Works regardless of how many subdirectory levels the spec file is nested
  # under specs/ - the repo root is found by walking up the directory tree.
  #
  # For a spec at:
  #   spec/contracts/consumer/external/specs/artifact_registry/index_spec.rb
  # the contract dir will be:
  #   spec/contracts/contracts/external/artifact_registry/
  #
  # Usage in every consumer spec:
  #   CONTRACT_DIR = PactHelper.contract_dir(__dir__)
  #
  # IMPORTANT: Each external service MUST have its own dedicated CI job that runs
  # only that service's spec file(s). Do NOT run multiple service specs in the same
  # CI job or RSpec process.
  #
  # Reason: Pact.configure sets pact_dir globally (process-wide singleton). If two
  # service specs are loaded in the same process, the last one to load wins and all
  # contracts write to that directory, breaking the at_exit rename for the other service.
  #
  # CI job pattern (one job per service):
  #   rspec spec/contracts/consumer/external/specs/artifact_registry/
  #   rspec spec/contracts/consumer/external/specs/<new_service>/
  #
  # @param spec_dir [String] pass __dir__ from the calling spec file
  # @return [String] absolute path to the contract output directory
  def self.contract_dir(spec_dir)
    # Extract only the service segment (first directory after 'specs/').
    # Contracts are stored per-service, not per-resource, matching the GCS
    # bucket layout: <bucket>/<service-slug>/<version>/<contract>.json
    parts = spec_dir.split('/specs/', 2)
    raise "Cannot derive service name from path: #{spec_dir}" unless parts.length == 2

    service = parts.last.split('/').first
    repo_root = find_repo_root(spec_dir)
    dir = File.join(repo_root, 'spec', 'contracts', 'contracts', 'external', service)
    FileUtils.mkdir_p(dir)
    dir
  end

  # Walks up the directory tree from the given path until it finds the
  # repository root, identified by the presence of a Gemfile.
  def self.find_repo_root(path)
    current = File.expand_path(path)
    until File.exist?(File.join(current, 'Gemfile'))
      parent = File.dirname(current)
      raise "Could not find repo root from #{path}" if parent == current

      current = parent
    end
    current
  end
  private_class_method :find_repo_root
end
