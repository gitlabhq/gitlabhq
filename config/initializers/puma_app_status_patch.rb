# frozen_string_literal: true

return unless defined?(::Puma)

require 'puma/const'

# This patches Puma with https://github.com/puma/puma/pull/3787.
# This is only needed if the control app is enabled.
raise if Gem::Version.new(Puma::Const::PUMA_VERSION) > Gem::Version.new('7.1.0')

require "puma/app/status"

module PumaAppStatusPatch
  ALLOWED_COMMANDS = %w[gc-stats stats].freeze

  def call(env)
    # resp_type is processed by following case statement, return
    # is a number (status) or a string used as the body of a 200 response
    command = env['PATH_INFO'][%r{/([^/]+)$}, 1]

    return rack_response(404, "Command disabled", 'text/plain') unless ALLOWED_COMMANDS.include?(command)

    super
  end
end

Puma::App::Status.prepend(PumaAppStatusPatch)
