# frozen_string_literal: true

require 'json'

# Shared functionality for Frontend Islands CI automation scripts
#
# This module provides common constants and methods used by both:
# - scripts/validate_fe_islands_ci.rb (strict validation in CI and lefthook)
# - scripts/update_fe_islands_ci.rb (automated CI configuration updates)
#
# == Architecture
#
# The system uses a Single Source of Truth (SSOT) pattern for CI parallelization:
# - `.fe-islands-parallel` template in frontend.gitlab-ci.yml defines FE_APP_DIR matrix
# - All parallelized jobs extend this template and inherit the matrix automatically
# - Scripts update ONE place, all jobs get the change via GitLab CI inheritance
# - Validation verifies both matrix content AND that jobs extend the template correctly
#
# This centralized approach eliminates duplicate matrix definitions and ensures
# all parallel jobs stay synchronized automatically through template inheritance.
#
# == Extending the Automation System
#
# === Adding a New Required Script
#
# If all apps must have a new script (e.g., 'format', 'typecheck'):
#
#   REQUIRED_SCRIPTS = %w[lint lint:types test build format].freeze
#
# Both validation and update scripts will automatically enforce this requirement.
#
# === Adding a New Parallel Job
#
# If you add a new CI job that should run per-app in parallel:
#
# 1. Add the job to your CI YAML and make it extend `.fe-islands-parallel`:
#
#    my-new-fe-islands-job:
#      extends:
#        - .some-base
#        - .fe-islands-parallel  # Inherits the matrix automatically!
#      script:
#        - cd ee/frontend_islands/apps/${FE_APP_DIR}
#        - yarn run my-command
#
# 2. Add the job to the JOBS_EXTENDING_TEMPLATE array:
#
#    JOBS_EXTENDING_TEMPLATE = [
#      { name: 'type-check-fe-islands', file: SETUP_CI_FILE },
#      { name: '.eslint:fe-islands', file: STATIC_ANALYSIS_CI_FILE },
#      { name: 'test-fe-islands', file: FRONTEND_CI_FILE },
#      { name: 'my-new-fe-islands-job', file: FRONTEND_CI_FILE }
#    ].freeze
#
# 3. Done! The job automatically:
#    - Gets the FE_APP_DIR matrix from `.fe-islands-parallel` template
#    - Updates when you run the update script (template inheritance)
#    - Is validated by the validation script
#
# === Important Notes
#
# - ALL parallelized FE islands jobs MUST extend `.fe-islands-parallel`
# - Jobs that build/process all apps at once (like compile-fe-islands) should NOT extend it
# - The validation script verifies jobs correctly extend the template
# - Changes to this module affect both validation and update scripts
module FeIslandsCiShared
  # CI Configuration Files
  STATIC_ANALYSIS_CI_FILE = '.gitlab/ci/static-analysis.gitlab-ci.yml'
  FRONTEND_CI_FILE = '.gitlab/ci/frontend.gitlab-ci.yml'
  SETUP_CI_FILE = '.gitlab/ci/setup.gitlab-ci.yml'

  # Frontend Islands Directory
  APPS_DIR = 'ee/frontend_islands/apps'

  # Single Source of Truth (SSOT) template for FE_APP_DIR matrix parallelization
  SSOT_TEMPLATE_NAME = '.fe-islands-parallel'
  SSOT_TEMPLATE_FILE = FRONTEND_CI_FILE

  # Jobs that extend the SSOT template (used for validation)
  # All these jobs inherit the FE_APP_DIR matrix from .fe-islands-parallel
  # Note: compile-fe-islands is NOT included as it builds all apps at once (not parallelized)
  JOBS_EXTENDING_TEMPLATE = [
    { name: 'type-check-fe-islands', file: SETUP_CI_FILE },
    { name: '.eslint:fe-islands', file: STATIC_ANALYSIS_CI_FILE },
    { name: 'test-fe-islands', file: FRONTEND_CI_FILE }
  ].freeze

  # Required scripts in package.json for an app to be valid
  REQUIRED_SCRIPTS = %w[lint lint:types test build].freeze

  # Discover app directories with valid package.json and required scripts
  # @return [Array<String>] sorted list of valid app directory names
  def discover_app_directories
    return [] unless Dir.exist?(APPS_DIR)

    Dir.entries(APPS_DIR)
       .select { |entry| Dir.exist?(File.join(APPS_DIR, entry)) }
       .reject { |entry| entry.start_with?('.') }
       .select { |entry| has_required_scripts?(entry) }
       .sort
  end

  # Check if app has required scripts in package.json
  # @param app_dir [String] app directory name
  # @param warn_on_missing [Boolean] whether to print warnings for missing scripts
  # @return [Boolean] true if app has all required scripts
  def has_required_scripts?(app_dir, warn_on_missing: false)
    package_json = read_package_json(app_dir)
    return false unless package_json

    has_all = REQUIRED_SCRIPTS.all? { |script| package_json.dig('scripts', script) }

    if warn_on_missing && !has_all
      missing = REQUIRED_SCRIPTS.reject { |script| package_json.dig('scripts', script) }
      warn "⚠  Warning: #{app_dir} is missing required script(s): #{missing.join(', ')}"
    end

    has_all
  end

  # Read and parse package.json for an app
  # @param app_dir [String] app directory name
  # @return [Hash, nil] parsed JSON or nil if not found/invalid
  def read_package_json(app_dir, warn_on_error: false)
    package_json_path = File.join(APPS_DIR, app_dir, 'package.json')
    return unless File.exist?(package_json_path)

    JSON.parse(File.read(package_json_path))
  rescue JSON::ParserError
    warn "⚠  Warning: Could not parse #{package_json_path}" if warn_on_error
    nil
  end

  # Extract FE_APP_DIR array from the SSOT template
  # @param file_path [String] CI file path containing the template
  # @param template_name [String] template name (e.g., '.fe-islands-parallel')
  # @return [Array<String>, nil] sorted array of app names or nil if not found
  def extract_template_matrix(file_path, template_name)
    return unless File.exist?(file_path)

    content = File.read(file_path)
    # Match template definition with FE_APP_DIR matrix
    # Format: .template-name:\n  parallel:\n    matrix:\n      - FE_APP_DIR: ["app1", "app2"]
    match = content.match(/#{Regexp.escape(template_name)}:.*?FE_APP_DIR:\s*\[(.*?)\]/m)
    return unless match

    apps_string = match[1]
    apps_string.scan(/"([^"]+)"/).flatten.sort
  end

  # Check if a job extends a specific template
  # @param file_path [String] CI file path containing the job
  # @param job_name [String] job name to check
  # @param template_name [String] template name to verify extension of
  # @return [Boolean] true if job extends the template
  def job_extends_template?(file_path, job_name, template_name)
    return false unless File.exist?(file_path)

    content = File.read(file_path)
    # Match job definition with extends section
    # Format: job-name:\n  extends:\n    - template1\n    - template2
    job_match = content.match(/^#{Regexp.escape(job_name)}:.*?extends:(.*?)(?=^\S|\z)/m)
    return false unless job_match

    extends_section = job_match[1]
    # Check if the template is listed in the extends section
    extends_section.include?("- #{template_name}")
  end

  # Get list of missing scripts for an app
  # @param app_dir [String] app directory name
  # @return [Array<String>] list of missing items (scripts or package.json issues)
  def get_missing_scripts(app_dir)
    package_json_path = File.join(APPS_DIR, app_dir, 'package.json')
    return ['package.json'] unless File.exist?(package_json_path)

    package_json = JSON.parse(File.read(package_json_path))
    REQUIRED_SCRIPTS.reject { |script| package_json.dig('scripts', script) }
  rescue JSON::ParserError
    ['package.json (invalid JSON)']
  end
end
