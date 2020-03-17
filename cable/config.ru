# frozen_string_literal: true

require ::File.expand_path('../../config/environment', __FILE__)
Rails.application.eager_load!

run ActionCable.server
