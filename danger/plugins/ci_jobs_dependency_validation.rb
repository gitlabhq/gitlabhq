# frozen_string_literal: true

require_relative '../../tooling/danger/ci_jobs_dependency_validation'

module Danger
  class CiJobsDependencyValidation < ::Danger::Plugin
    include Tooling::Danger::CiJobsDependencyValidation
  end
end
