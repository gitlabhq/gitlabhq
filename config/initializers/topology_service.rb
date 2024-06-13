# frozen_string_literal: true

topology_service_settings = Settings.topology_service
return unless topology_service_settings.enabled

# Configuring the Topology Service will be done here
# Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/451052
# The code should look like when configuring
# the topology service client.

# address = topology_service_settings.address
# cell_settings = Settings.cell # will be used for the topology service requests metadata
# See this draft MR for an example:
# https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146528/diffs
#
# claim_service = Gitlab::Cells::ClaimService::Stub.new(address, :this_channel_is_insecure)
