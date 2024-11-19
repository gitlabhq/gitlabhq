# frozen_string_literal: true

# Timeout if Regular expression takes more than fifty seconds to compute.
# This is a conservative value and is to be evaluated later.
# This value can be overridden using the REGEXP_TIMEOUT_SECONDS environment value
Regexp.timeout = ENV.fetch('REGEXP_TIMEOUT_SECONDS', 50).to_f if RUBY_VERSION > "3.2"
