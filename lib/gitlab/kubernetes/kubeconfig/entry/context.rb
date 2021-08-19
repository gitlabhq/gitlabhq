# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Kubeconfig
      module Entry
        class Context
          attr_reader :name

          def initialize(name:, cluster:, user:, namespace: nil)
            @name = name
            @cluster = cluster
            @user = user
            @namespace = namespace
          end

          def to_h
            {
              name: name,
              context: context
            }
          end

          private

          attr_reader :cluster, :user, :namespace

          def context
            {
              cluster: cluster,
              namespace: namespace,
              user: user
            }.compact
          end
        end
      end
    end
  end
end
