# frozen_string_literal: true

require 'openssl'

# As https://docs.openssl.org/3.0/man3/SSL_CTX_set_options/#notes
# describes about `SSL_OP_IGNORE_UNEXPECTED_EOF`:
#
# Some TLS implementations do not send the mandatory close_notify alert
# on shutdown. If the application tries to wait for the close_notify
# alert but the peer closes the connection without sending it, an error
# is generated. When this option is enabled the peer does not need to
# send the close_notify alert and a closed connection will be treated as
# if the close_notify alert was received.
#
# As discussed in https://github.com/ruby/openssl/pull/730, ignoring these
# unexpected EOFs should not be done by default, but some GitLab servers
# have to talk to services that do not close SSL connections properly.
# This should ONLY be enabled for self-managed customers who need
# a way to interoperate with legacy services.
if Gitlab::Utils.to_boolean(ENV['SSL_IGNORE_UNEXPECTED_EOF'])
  OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_IGNORE_UNEXPECTED_EOF
end
