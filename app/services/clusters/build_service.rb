# frozen_string_literal: true
module Clusters
  class BuildService
    def initialize(subject)
      @subject = subject
    end

    def execute
      ::Clusters::Cluster.new.tap do |cluster|
        case @subject
        when ::Project
          cluster.cluster_type = :project_type
        when ::Group
          cluster.cluster_type = :group_type
        when Instance
          cluster.cluster_type = :instance_type
        else
          raise NotImplementedError
        end
      end
    end
  end
end
