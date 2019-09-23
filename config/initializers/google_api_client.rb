# frozen_string_literal: true
#
# google-api-client >= 0.26.0 supports enabling CloudRun and Istio during
# cluster creation, but fog-google currently hard deps on '~> 0.23.0', which
# prevents us from upgrading. We are injecting these options as hashes below
# as a workaround until this is resolved.
#
# This can be removed once fog-google and google-api-client can be upgraded.
# See https://gitlab.com/gitlab-org/gitlab-ce/issues/66630 for more details.
#

require 'google/apis/container_v1beta1'

Google::Apis::ContainerV1beta1::AddonsConfig::Representation.tap do |representation|
  representation.hash :cloud_run_config, as: 'cloudRunConfig'
  representation.hash :istio_config, as: 'istioConfig'
end
