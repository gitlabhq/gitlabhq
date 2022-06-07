# frozen_string_literal: true

require 'spec_helper'
require 'zeitwerk'
require_relative 'helpers/users_helper'

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
