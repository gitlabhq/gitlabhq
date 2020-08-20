# frozen_string_literal: true

class ClusterErrorEntity < Grape::Entity
  expose :connection_error
  expose :metrics_connection_error
  expose :node_connection_error
end
