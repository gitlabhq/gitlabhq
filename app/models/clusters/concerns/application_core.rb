# frozen_string_literal: true

module Clusters
  module Concerns
    module ApplicationCore
      extend ActiveSupport::Concern

      included do
        include ::Clusters::Concerns::KubernetesLogger

        belongs_to :cluster, class_name: 'Clusters::Cluster', foreign_key: :cluster_id

        validates :cluster, presence: true

        after_initialize :set_initial_status

        def helm_command_module
          case cluster.helm_major_version
          when 3
            Gitlab::Kubernetes::Helm::V3
          when 2
            Gitlab::Kubernetes::Helm::V2
          else
            raise "Invalid Helm major version"
          end
        end

        def set_initial_status
          return unless not_installable?

          self.status = status_states[:installable]
        end

        def can_uninstall?
          allowed_to_uninstall?
        end

        # All new applications should uninstall by default
        # Override if there's dependencies that needs to be uninstalled first
        def allowed_to_uninstall?
          true
        end

        def self.application_name
          self.to_s.demodulize.underscore
        end

        def self.association_name
          :"application_#{application_name}"
        end

        def name
          self.class.application_name
        end

        def schedule_status_update
          # Override if you need extra data synchronized
          # from K8s after installation
        end

        def update_command
          install_command.tap do |command|
            command.version = version
          end
        end

        def uninstall_command
          helm_command_module::DeleteCommand.new(
            name: name,
            rbac: cluster.platform_kubernetes_rbac?,
            files: files
          )
        end

        def prepare_uninstall
          # Override if your application needs any action before
          # being uninstalled by Helm
        end

        def post_uninstall
          # Override if your application needs any action after
          # being uninstalled by Helm
        end
      end
    end
  end
end

Clusters::Concerns::ApplicationCore.prepend_mod_with('Clusters::Concerns::ApplicationCore')
