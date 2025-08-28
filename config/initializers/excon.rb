# frozen_string_literal: true

require 'openssl'

# Excon ships its own bundled certs by default. Avoid confusion
# by using the same set that GitLab uses.
Excon.defaults[:ssl_ca_file] = OpenSSL::X509::DEFAULT_CERT_FILE
Excon.defaults[:ssl_verify_peer] = true

# These options were changed in excon 1.0, but it's not clear
# if they will break something. For now preserve the original settings.
Excon.defaults[:middlewares] -= [Excon::Middleware::Decompress]
Excon.defaults[:omit_default_port] = false
