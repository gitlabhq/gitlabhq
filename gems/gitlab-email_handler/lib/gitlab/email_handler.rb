# frozen_string_literal: true

require_relative 'email_handler/version'

# Pure, dependency-free incoming email identification: regex parsing of mail
# keys into a Target. No Rails, gRPC or HTTP dependencies. Resolving a Target to
# a cell and forwarding the email are the responsibility of the consumer (the
# mail_room service), not this gem.
require_relative 'email_handler/reply_key'
require_relative 'email_handler/target'
require_relative 'email_handler/identification'
require_relative 'email_handler/identifier'
require_relative 'email_handler/custom_email'
require_relative 'email_handler/mail_key'
