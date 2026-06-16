# frozen_string_literal: true

require_relative '../../tooling/danger/ci_server_fqdn'

module Danger
  class CiServerFqdn < ::Danger::Plugin
    include Tooling::Danger::CiServerFqdn
  end
end
