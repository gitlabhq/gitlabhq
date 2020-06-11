# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      class ResetCommand < BaseCommand
        include ClientCommand

        def generate_script
          super + [
            reset_helm_command,
            delete_tiller_replicaset,
            delete_tiller_clusterrolebinding
          ].join("\n")
        end

        def pod_name
          "uninstall-#{name}"
        end

        private

        # This method can be delete once we upgrade Helm to > 12.13.0
        # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/27096#note_159695900
        #
        # Tracking this method to be removed here:
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/52791#note_199374155
        def delete_tiller_replicaset
          delete_args = %w[replicaset -n gitlab-managed-apps -l name=tiller]

          Gitlab::Kubernetes::KubectlCmd.delete(*delete_args)
        end

        def delete_tiller_clusterrolebinding
          delete_args = %w[clusterrolebinding tiller-admin]

          Gitlab::Kubernetes::KubectlCmd.delete(*delete_args)
        end

        def reset_helm_command
          command = %w[helm reset] + optional_tls_flags

          command.shelljoin
        end
      end
    end
  end
end
