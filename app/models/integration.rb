# frozen_string_literal: true

# To add new integration you should build a class inherited from Integration
# and implement a set of methods
class Integration < ApplicationRecord
  include Integrations::Base::Integration
end
