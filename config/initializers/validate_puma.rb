# frozen_string_literal: true

if Gitlab::Runtime.puma? && ::Puma.cli_config.options[:workers].to_i == 0
  return if allow_single_mode?

  raise 'Puma is only supported in Cluster-mode: workers > 0'
end

def allow_single_mode?
  return false if Gitlab.com?

  Gitlab::Utils.to_boolean(ENV['PUMA_SKIP_CLUSTER_VALIDATION'])
end
