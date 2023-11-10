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
          @current_context = nil
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

        def merge_yaml(kubeconfig_yaml)
          return unless kubeconfig_yaml

          kubeconfig_yaml = YAML.safe_load(kubeconfig_yaml, symbolize_names: true)
          kubeconfig_yaml[:users].each do |user|
            add_user(
              name: user[:name],
              token: user.dig(:user, :token)
            )
          end
          kubeconfig_yaml[:clusters].each do |cluster|
            ca_pem = cluster.dig(:cluster, :'certificate-authority-data')&.then do |data|
              Base64.strict_decode64(data)
            end

            add_cluster(
              name: cluster[:name],
              url: cluster.dig(:cluster, :server),
              ca_pem: ca_pem
            )
          end
          kubeconfig_yaml[:contexts].each do |context|
            add_context(
              name: context[:name],
              **context[:context]&.slice(:cluster, :user, :namespace)
            )
          end
          @current_context = kubeconfig_yaml[:'current-context']
        end

        def to_h
          {
            apiVersion: 'v1',
            kind: 'Config',
            clusters: clusters.map(&:to_h),
            users: users.map(&:to_h),
            contexts: contexts.map(&:to_h),
            'current-context': current_context
          }.compact
        end

        def to_yaml
          YAML.dump(to_h.deep_stringify_keys)
        end

        private

        attr_reader :clusters, :users, :contexts, :current_context

        def new_entry(entry, **args)
          ENTRIES.fetch(entry).new(**args)
        end
      end
    end
  end
end
