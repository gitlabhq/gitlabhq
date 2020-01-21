# frozen_string_literal: true

if Gitlab::Runtime.puma? && ::Puma.cli_config.options[:workers].to_i.zero?
  raise 'Puma is only supported in Cluster-mode: workers > 0'
end
