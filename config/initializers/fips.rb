# frozen_string_literal: true

Labkit::FIPS.enable_fips_mode! if Gitlab::FIPS.enabled?
