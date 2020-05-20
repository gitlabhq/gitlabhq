# frozen_string_literal: true

class ClusterEntity < Grape::Entity
  include RequestAwareEntity

  expose :cluster_type
  expose :enabled
  expose :environment_scope
  expose :name
  expose :nodes
  expose :status_name, as: :status
  expose :status_reason
  expose :applications, using: ClusterApplicationEntity

  expose :path do |cluster|
    Clusters::ClusterPresenter.new(cluster).show_path # rubocop: disable CodeReuse/Presenter
  end
end
