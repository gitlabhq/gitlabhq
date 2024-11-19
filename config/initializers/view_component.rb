# frozen_string_literal: true

require "view_component/deprecation"

ViewComponent::Deprecation.silenced = Rails.env.production? || Rails.env.test?
