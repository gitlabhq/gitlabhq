#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'optparse'
require_relative 'fe_islands_ci_shared'

# Script to update the frontend islands CI configuration with current app directories
# Uses shared functionality from fe_islands_ci_shared.rb
class UpdateFeIslandsCi
  include FeIslandsCiShared

  def self.update!(dry_run: false)
    new.update!(dry_run: dry_run)
  end

  def update!(dry_run: false)
    app_dirs = discover_app_directories
    configured_apps = extract_configured_apps

    if app_dirs.empty?
      puts "⚠️  No app directories found in #{APPS_DIR}"
      puts "  Make sure app directories contain a package.json with required scripts: #{REQUIRED_SCRIPTS.join(', ')}"
      return
    end

    puts "Discovered frontend island apps:"
    app_dirs.each { |app| puts "  - #{app}" }
    puts

    if app_dirs == configured_apps
      puts "✅ CI configuration is already up to date"
      puts "   No changes needed."
      return
    end

    puts "Current CI configuration:"

    if configured_apps.empty?
      puts "  (no apps configured)"
    else
      configured_apps.each { |app| puts "  - #{app}" }
    end

    puts

    added = app_dirs - configured_apps
    removed = configured_apps - app_dirs

    unless added.empty?
      puts "Apps to be added to CI:"
      added.each { |app| puts "  + #{app}" }
      puts
    end

    unless removed.empty?
      puts "Apps to be removed from CI:"
      removed.each { |app| puts "  - #{app}" }
      puts
    end

    if dry_run
      puts "DRY RUN: No changes made"
      puts "Run without --dry-run to apply changes"
      puts
      puts "Template that would be updated:"
      puts "  - #{SSOT_TEMPLATE_NAME} in #{SSOT_TEMPLATE_FILE}"
      puts
      puts "Jobs that inherit from this template:"
    else
      update_template(app_dirs)
      puts "✓ Updated CI configuration"
      puts "  Template: #{SSOT_TEMPLATE_NAME}"
      puts "  New matrix: #{app_dirs.inspect}"
      puts
      puts "Jobs that inherit this matrix:"
    end

    JOBS_EXTENDING_TEMPLATE.each do |job|
      puts "  - #{job[:name]} in #{job[:file]}"
    end
  end

  private

  # Override to show warnings for apps with missing scripts
  def discover_app_directories
    return [] unless Dir.exist?(APPS_DIR)

    Dir.entries(APPS_DIR)
       .select { |entry| Dir.exist?(File.join(APPS_DIR, entry)) }
       .reject { |entry| entry.start_with?('.') }
       .select { |entry| has_required_scripts?(entry, warn_on_missing: true) }
       .sort
  end

  def extract_configured_apps
    # Extract from SSOT template (all jobs inherit from this)
    extract_template_matrix(SSOT_TEMPLATE_FILE, SSOT_TEMPLATE_NAME) || []
  end

  def update_template(app_dirs)
    # Update only the SSOT template - all jobs that extend it automatically inherit the change
    return unless File.exist?(SSOT_TEMPLATE_FILE)

    content = File.read(SSOT_TEMPLATE_FILE)

    # Update the template's FE_APP_DIR matrix
    # Format: .fe-islands-parallel:\n  parallel:\n    matrix:\n      - FE_APP_DIR: ["app1", "app2"]
    updated_content = content.gsub(
      /^(#{Regexp.escape(SSOT_TEMPLATE_NAME)}:.*?parallel:\s*matrix:\s*-\s*FE_APP_DIR:\s*)\[.*?\]/mo
    ) do
      "#{::Regexp.last_match(1)}#{app_dirs.inspect}"
    end

    # Only write if content changed
    File.write(SSOT_TEMPLATE_FILE, updated_content) if updated_content != content
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { dry_run: false }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} [options]"
    opts.on('-d', '--dry-run', 'Show what would be changed without modifying files') do
      options[:dry_run] = true
    end
    opts.on('-h', '--help', 'Display this help message') do
      puts opts
      exit
    end
  end.parse!

  UpdateFeIslandsCi.update!(dry_run: options[:dry_run])
end
