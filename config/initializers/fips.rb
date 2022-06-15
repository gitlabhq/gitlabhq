# frozen_string_literal: true

Gitlab::FIPS.enable_fips_mode! if Gitlab::FIPS.enabled?
