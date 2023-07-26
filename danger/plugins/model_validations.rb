# frozen_string_literal: true

require_relative '../../tooling/danger/model_validations'

module Danger
  class ModelValidations < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::ModelValidations
  end
end
