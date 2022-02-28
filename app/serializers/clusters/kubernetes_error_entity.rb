# frozen_string_literal: true

module Clusters
  class KubernetesErrorEntity < Grape::Entity
    expose :connection_error
    expose :metrics_connection_error
    expose :node_connection_error
  end
end
