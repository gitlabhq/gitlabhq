# frozen_string_literal: true

require 'openssl'

# Excon ships its own bundled certs by default. Avoid confusion
# by using the same set that GitLab uses.
Excon.defaults[:ssl_ca_file] = OpenSSL::X509::DEFAULT_CERT_FILE
Excon.defaults[:ssl_verify_peer] = true
