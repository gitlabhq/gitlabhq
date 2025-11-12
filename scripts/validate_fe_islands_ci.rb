#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'fe_islands_ci_shared'

# Script to validate that frontend islands CI configuration matches actual app directories
# Uses shared functionality from fe_islands_ci_shared.rb
class ValidateFeIslandsCi
  include FeIslandsCiShared

  def self.validate!
    new.validate!
  end

  def validate!
    all_app_dirs = discover_all_app_directories
    apps_with_valid_scripts = discover_app_directories
    apps_with_missing_scripts = all_app_dirs - apps_with_valid_scripts

    # 1. Extract matrix from SSOT template
    configured_apps = extract_template_matrix(SSOT_TEMPLATE_FILE, SSOT_TEMPLATE_NAME)

    unless configured_apps
      puts "✗ Could not find #{SSOT_TEMPLATE_NAME} template in #{SSOT_TEMPLATE_FILE}"
      exit 1
    end

    # 2. Verify all expected jobs extend the template
    invalid_jobs = []
    JOBS_EXTENDING_TEMPLATE.each do |job|
      unless job_extends_template?(job[:file], job[:name], SSOT_TEMPLATE_NAME)
        invalid_jobs << "#{job[:name]} in #{job[:file]}"
      end
    end

    unless invalid_jobs.empty?
      print_template_extension_error(invalid_jobs)
      exit 1
    end

    # 3. STRICT: Fail validation if any apps have missing scripts
    unless apps_with_missing_scripts.empty?
      print_missing_scripts_error(apps_with_missing_scripts)
      exit 1
    end

    # 4. Check if actual apps match configured apps
    if apps_with_valid_scripts == configured_apps
      puts "✓ Frontend Islands CI configuration is up to date"
      puts "  Template: #{SSOT_TEMPLATE_NAME}"
      puts "  Apps configured: #{configured_apps.join(', ')}"
      # rubocop:disable Rails/Pluck -- JOBS_EXTENDING_TEMPLATE is a plain array, not ActiveRecord
      puts "  Jobs extending template: #{JOBS_EXTENDING_TEMPLATE.map { |j| j[:name] }.join(', ')}"
      # rubocop:enable Rails/Pluck
      exit 0
    else
      print_validation_error(apps_with_valid_scripts, configured_apps)
      exit 1
    end
  end

  private

  def discover_all_app_directories
    return [] unless Dir.exist?(APPS_DIR)

    Dir.entries(APPS_DIR)
       .select { |entry| Dir.exist?(File.join(APPS_DIR, entry)) }
       .reject { |entry| entry.start_with?('.') }
       .sort
  end

  def print_template_extension_error(invalid_jobs)
    puts "✗ Frontend Islands CI validation failed: Jobs not extending template!"
    puts
    puts "The following jobs do not extend #{SSOT_TEMPLATE_NAME}:"
    invalid_jobs.each { |job| puts "  - #{job}" }
    puts
    puts "All parallelized FE islands jobs must extend the #{SSOT_TEMPLATE_NAME} template."
    puts "To fix this, add '- #{SSOT_TEMPLATE_NAME}' to the 'extends' section of each job."
    puts
  end

  def print_missing_scripts_error(apps)
    puts "✗ Frontend Islands validation failed: Apps with invalid or missing scripts detected!"
    puts
    puts "The following apps exist in #{APPS_DIR} but are missing required scripts:"
    apps.each do |app|
      missing = get_missing_scripts(app)
      puts "  - #{app}: missing #{missing.join(', ')}"
    end
    puts
    puts "All apps in #{APPS_DIR} must have:"
    puts "  - A valid package.json file"
    REQUIRED_SCRIPTS.each do |script|
      puts "  - A '#{script}' script in package.json"
    end
    puts
    puts "Either:"
    puts "  1. Add the missing scripts to these apps, OR"
    puts "  2. Remove the incomplete app directories"
  end

  def print_validation_error(actual_apps, configured_apps)
    puts "✗ Frontend Islands CI configuration is out of sync!"
    puts
    puts "Actual apps in #{APPS_DIR}:"

    if actual_apps.empty?
      puts "  (none)"
    else
      actual_apps.each { |app| puts "  - #{app}" }
    end

    puts
    puts "Apps configured in #{SSOT_TEMPLATE_NAME} template:"

    if configured_apps.empty?
      puts "  (none)"
    else
      configured_apps.each { |app| puts "  - #{app}" }
    end

    puts

    missing_in_ci = actual_apps - configured_apps
    extra_in_ci = configured_apps - actual_apps

    unless missing_in_ci.empty?
      puts "Missing in CI configuration:"
      missing_in_ci.each { |app| puts "  - #{app}" }
      puts
    end

    unless extra_in_ci.empty?
      puts "Configured but not found in directory:"
      extra_in_ci.each { |app| puts "  - #{app}" }
      puts
    end

    puts "To fix this, run:"
    puts "  ruby scripts/update_fe_islands_ci.rb"
    puts
  end
end

ValidateFeIslandsCi.validate! if __FILE__ == $PROGRAM_NAME
