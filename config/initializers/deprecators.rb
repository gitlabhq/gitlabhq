# frozen_string_literal: true

Rails.application.deprecators[:qa] = ActiveSupport::Deprecation.new('19.0', 'qa')
