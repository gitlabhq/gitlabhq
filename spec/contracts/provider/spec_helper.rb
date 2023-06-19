# frozen_string_literal: true

require 'spec_helper'
require 'zeitwerk'
require 'gitlab/rspec/all'
require_relative 'helpers/users_helper'
require_relative('../../../ee/spec/contracts/provider/spec_helper') if Gitlab.ee?
require Rails.root.join("spec/support/helpers/rails_helpers.rb")

# Opt out of telemetry collection. We can't allow all engineers, and users who install GitLab from source, to be
# automatically enrolled in sending data on their usage without their knowledge.
ENV['PACT_DO_NOT_TRACK'] = 'true'

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers
  config.include FactoryBot::Syntax::Methods

  config.before do
    user = create(:user, name: Provider::UsersHelper::CONTRACT_USER_NAME).tap do |user|
      user.current_sign_in_at = Time.current
    end

    sign_in user
  end
end

Pact.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include RailsHelpers
  config.include StubENV
end

module SpecHelper
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
