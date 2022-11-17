#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'
require 'open3'

module LintTemplatesBash
  module_function

  EXCLUDED_RULES = [
    "SC2046", "SC2086", # will be fixed later: https://gitlab.com/gitlab-org/gitlab/-/issues/352973
    "SC1090", "SC1091", # we do not have access to sourced files for analysis.
    "SC2154", # Referencing undefined variables is common and adding per-line exceptions for them is unintuitive for end-users
    "SC2164" # CI/CD automatically fails if attempting to change to a directory which does not exist.
  ].join(",").freeze

  EXCLUDED_TEMPLATES = [
    "dotNET.gitlab-ci.yml" # Powershell
  ].freeze

  def run
    failed_templates = Gitlab::Template::GitlabCiYmlTemplate.all.filter_map do |template|
      next if EXCLUDED_TEMPLATES.include?(template.full_name)

      success = check_template(template)

      template.full_name unless success
    end

    if failed_templates.any?
      puts "The following templates have shellcheck violations:"
      puts failed_templates.join("\n")
      exit 1
    end
  end

  def process_content(content)
    Gitlab::Ci::YamlProcessor.new(content).execute
  end

  def job_script(job)
    parts = [:before_script, :script, :after_script].map do |key|
      job[key]&.join("\n")
    end.compact

    parts.prepend("#!/bin/bash\n").join("\n")
  end

  def shellcheck(script_content)
    combined_streams, status = Open3.capture2e("shellcheck --exclude='#{EXCLUDED_RULES}' -", stdin_data: script_content)

    [combined_streams, status.success?]
  end

  def check_job(job)
    shellcheck(job_script(job))
  end

  def check_template(template)
    parsed = process_content(template.content)

    unless parsed.valid?
      warn "#{template.full_name} is invalid: #{parsed.errors.inspect}"
      return true
    end

    results = parsed.jobs.map do |name, job|
      out, success = check_job(job)

      unless success
        puts "The '#{name}' job in #{template.full_name} has shellcheck failures:"
        puts out
      end

      success
    end

    results.all?
  end
end

LintTemplatesBash.run
