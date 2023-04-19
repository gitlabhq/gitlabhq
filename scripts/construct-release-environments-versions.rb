#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

class ReleaseEnvironmentsModel
  COMPONENTS = %w[gitaly registry kas mailroom pages gitlab shell].freeze

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
  def generate_json(environment)
    output_json = {}
    COMPONENTS.each do |component|
      output_json[component.to_s] = "#{environment}-#{ENV['CI_COMMIT_SHORT_SHA']}"
    end
    JSON.generate(output_json)
  end
end

# Outputs in `dotenv` format the ENVIRONMENT and VERSIONS to pass to release environments e.g.
# ENVIRONMENT=15-10-stable
# VERSIONS={"gitaly":"15-10-stable-c7c5131c","registry":"15-10-stable-c7c5131c","kas":"15-10-stable-c7c5131c", ...
if $PROGRAM_NAME == __FILE__
  environment = ENV['CI_COMMIT_REF_SLUG'].sub("-ee", "")
  puts "ENVIRONMENT=#{environment}"
  puts "VERSIONS=#{ReleaseEnvironmentsModel.new.generate_json(environment)}"
end
