# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'active_support/environment_inquirer'

module Rails
  extend self

  def env
    @env ||= ActiveSupport::EnvironmentInquirer.new(
      ENV["RAILS_ENV"].presence || ENV["RACK_ENV"].presence || "development"
    )
  end

  def root
    Pathname.new(File.expand_path('..', __dir__))
  end
end

# rubocop:enable Naming/FileName
