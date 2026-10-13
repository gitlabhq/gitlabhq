# frozen_string_literal: true

# Surface a redirected telemetry destination in the log of every process, so
# an operator can tell why version.gitlab.com is not receiving anything.
Gitlab::TelemetryEndpoint.log_configuration
