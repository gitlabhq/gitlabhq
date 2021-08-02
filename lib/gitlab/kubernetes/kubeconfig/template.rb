# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Kubeconfig
      class Template
        ENTRIES = {
          cluster: Gitlab::Kubernetes::Kubeconfig::Entry::Cluster,
          user: Gitlab::Kubernetes::Kubeconfig::Entry::User,
          context: Gitlab::Kubernetes::Kubeconfig::Entry::Context
        }.freeze

        def initialize
          @clusters = []
          @users = []
          @contexts = []
        end

        def valid?
          contexts.present?
        end

        def add_cluster(**args)
          clusters << new_entry(:cluster, **args)
        end

        def add_user(**args)
          users << new_entry(:user, **args)
        end

        def add_context(**args)
          contexts << new_entry(:context, **args)
        end

        def to_h
          {
            apiVersion: 'v1',
            kind: 'Config',
            clusters: clusters.map(&:to_h),
            users: users.map(&:to_h),
            contexts: contexts.map(&:to_h)
          }
        end

        def to_yaml
          YAML.dump(to_h.deep_stringify_keys)
        end

        private

        attr_reader :clusters, :users, :contexts

        def new_entry(entry, **args)
          ENTRIES.fetch(entry).new(**args)
        end
      end
    end
  end
end
