# frozen_string_literal: true
#
# fog-core v2 changed the namespace format:
#
# Old: Fog::<service>::<provider> (e.g. Fog::Storage::AWS).
# New: Fog::<provider>::<service> (e.g. Fog::AWS::Storage)
#
# To preserve backwards compatibility, fog-core v2.1.0 tries to load the
# old schema first, but falls back to the older version if that
# fails. This creates misleading warnings with fog-aws. See
# https://github.com/fog/fog-aws/issues/504#issuecomment-468067991 for
# more details.
#
# fog-core v2.1.2 reverses the load order
# (https://github.com/fog/fog-core/pull/229), which works for fog-aws
# but causes a stream of deprecation warnings for fog-google.
# fog-google locked the dependency on fog-core v2.1.0 as a result
# (https://github.com/fog/fog-google/issues/421) until the new namespace
# is supported.
#
# Since we currently have some Fog gems that have not been updated, this
# monkey patch makes a smarter decision about which namespace to try
# first. This squelches a significant number of warning messages.
#
# Since this patch is mostly cosmetic, it can be removed safely at any
# time, but it's probably best to wait until the following issues are
# closed:
#
# fog-google: https://github.com/fog/fog-google/issues/421
# fog-aliyun: https://github.com/fog/fog-aliyun/issues/23
module Fog
  module ServicesMixin
    # Gems that have not yet updated with the new fog-core namespace
    LEGACY_FOG_PROVIDERS = %w[google aliyun].freeze

    # rubocop:disable Gitlab/ConstGetInheritFalse
    def service_provider_constant(service_name, provider_name)
      args = service_provider_search_args(service_name, provider_name)
      Fog.const_get(args.first).const_get(*const_get_args(args.second))
    rescue NameError # Try to find the constant from in an alternate location
      Fog.const_get(args.second).const_get(*const_get_args(args.first))
    end

    def service_provider_search_args(service_name, provider_name)
      if LEGACY_FOG_PROVIDERS.include?(provider_name.downcase)
        [service_name, provider_name]
      else
        [provider_name, service_name]
      end
    end
    # rubocop:enable Gitlab/ConstGetInheritFalse
  end
end
