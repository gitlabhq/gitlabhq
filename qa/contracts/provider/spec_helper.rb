# frozen_string_literal: true

module SpecHelper
  unless ENV['CONTRACT_HOST']
    raise(ArgumentError, 'Contract tests require CONTRACT_HOST environment variable to be set!')
  end

  require_relative '../../../config/bundler_setup'
  Bundler.require(:default)

  root = File.expand_path('../', __dir__)

  loader = Zeitwerk::Loader.new
  loader.push_dir(root)

  loader.ignore("#{root}/consumer")
  loader.ignore("#{root}/contracts")

  loader.collapse("#{root}/provider/spec")

  loader.setup
end
