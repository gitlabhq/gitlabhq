# frozen_string_literal: true

require ::File.expand_path('../../config/environment', __FILE__)
Rails.application.eager_load!

ACTION_CABLE_SERVER = true

use ActionDispatch::RequestId, header: Rails.application.config.action_dispatch.request_id_header

run ActionCable.server
