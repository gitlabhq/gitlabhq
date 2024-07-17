#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

class ReleaseEnvironmentsModel
  COMPONENTS = %w[gitaly registry kas mailroom pages gitlab shell praefect].freeze

  # Will generate a json object that has a key for every component and a value which is the environment combined with
  # short sha
  # Example:
  # {
  #  "gitaly": "15-10-stable-c7c5131c",
  #  "registry": "15-10-stable-c7c5131c",
  #  "kas": "15-10-stable-c7c5131c",
  #  "mailroom": "15-10-stable-c7c5131c",
  #  "pages": "15-10-stable-c7c5131c",
  #  "gitlab": "15-10-stable-c7c5131c",
  #  "shell": "15-10-stable-c7c5131c"
  # }
  def generate_json
    output_json = {}
    COMPONENTS.each do |component|
      output_json[component.to_s] = image_tag.to_s
    end
    JSON.generate(output_json)
  end

  def set_required_env_vars?
    required_env_vars = %w[DEPLOY_ENV]

    required_env_vars.each do |var|
      if ENV.fetch(var, nil).to_s.empty?
        puts "Missing required environment variable: #{var}"
        return false
      end
    end
    true
  end

  def environment
    @environment ||= environment_base + (security_project? ? "-security" : "")
  end

  def image_tag
    @image_tag ||= "#{environment_base}-#{ENV['CI_COMMIT_SHORT_SHA']}"
  end

  private

  # This is to generate the environment name without "-security". It is used by the image tag
  def environment_base
    @environment_base ||= if release_tag_match
                            "#{release_tag_match[1]}-#{release_tag_match[2]}-stable"
                          else
                            ENV['CI_COMMIT_REF_NAME'].delete_suffix('-ee')
                          end
  end

  def release_tag_match
    @release_tag_match ||= ENV['CI_COMMIT_REF_NAME'].match(/^v?([\d]+)\.([\d]+)\.[\d]+[\d\w-]*-ee$/)
  end

  def security_project?
    ENV['CI_PROJECT_PATH'] == "gitlab-org/security/gitlab"
  end
end

# Outputs in `dotenv` format the ENVIRONMENT and VERSIONS to pass to release environments e.g.
# ENVIRONMENT=15-10-stable(-security)
# VERSIONS={"gitaly":"15-10-stable-c7c5131c","registry":"15-10-stable-c7c5131c","kas":"15-10-stable-c7c5131c", ...
if $PROGRAM_NAME == __FILE__
  model = ReleaseEnvironmentsModel.new
  raise "Missing required environment variable." unless model.set_required_env_vars?

  File.open(ENV['DEPLOY_ENV'], 'w') do |file|
    file.puts "ENVIRONMENT=#{model.environment}"
    file.puts "VERSIONS=#{model.generate_json}"
  end

  puts File.read(ENV['DEPLOY_ENV'])
end
