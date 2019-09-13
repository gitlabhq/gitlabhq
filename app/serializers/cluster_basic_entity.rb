# frozen_string_literal: true

class ClusterBasicEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  expose :path, if: -> (cluster) { can?(request.current_user, :read_cluster, cluster) } do |cluster|
    cluster.present(current_user: request.current_user).show_path
  end
end
