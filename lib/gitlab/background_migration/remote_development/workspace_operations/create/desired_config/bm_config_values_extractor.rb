# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module Create
          module DesiredConfig
            class BmConfigValuesExtractor # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
              include BmStates
              include BmWorkspaceOperationsConstants

              # rubocop:disable Metrics/MethodLength -- this is a won't fix
              # @param [Hash] context
              # @return [Hash]
              def self.extract(context) # rubocop:disable Metrics/AbcSize -- this is a won't fix
                context => {
                  workspace_id: workspace_id,
                  workspace_name: workspace_name,
                  workspace_desired_state_is_running: workspace_desired_state_is_running,
                  workspaces_agent_id: workspaces_agent_id,
                  workspaces_agent_config: workspaces_agent_config
                }

                domain_template = "{{.port}}-#{workspace_name}.#{workspaces_agent_config.dns_zone}"

                max_resources_per_workspace =
                  deep_sort_and_symbolize_hashes(workspaces_agent_config.max_resources_per_workspace)
                max_resources_per_workspace_sha256 = OpenSSL::Digest::SHA256.hexdigest(max_resources_per_workspace.to_s)

                default_resources_per_workspace_container =
                  deep_sort_and_symbolize_hashes(workspaces_agent_config.default_resources_per_workspace_container)

                shared_namespace = workspaces_agent_config.shared_namespace
                # TODO: Fix this as part of https://gitlab.com/gitlab-org/gitlab/-/issues/541902
                shared_namespace = "" if shared_namespace.nil?

                workspace_inventory_name = "#{workspace_name}#{WORKSPACE_INVENTORY}"
                secrets_inventory_name = "#{workspace_name}#{SECRETS_INVENTORY}"

                extra_annotations = {
                  "workspaces.gitlab.com/host-template": domain_template.to_s,
                  "workspaces.gitlab.com/id": workspace_id.to_s,
                  # NOTE: This annotation is added to cause the workspace to restart whenever the max resources change
                  "workspaces.gitlab.com/max-resources-per-workspace-sha256": max_resources_per_workspace_sha256
                }
                partial_reconcile_annotation = { ANNOTATION_KEY_INCLUDE_IN_PARTIAL_RECONCILIATION => "true" }
                agent_annotations = workspaces_agent_config.annotations
                common_annotations = deep_sort_and_symbolize_hashes(agent_annotations.merge(extra_annotations))
                common_annotations_for_partial_reconciliation =
                  deep_sort_and_symbolize_hashes(common_annotations.merge(partial_reconcile_annotation))
                secrets_inventory_annotations = deep_sort_and_symbolize_hashes(
                  common_annotations.merge("config.k8s.io/owning-inventory": secrets_inventory_name)
                )
                workspace_inventory_annotations = deep_sort_and_symbolize_hashes(
                  common_annotations.merge("config.k8s.io/owning-inventory": workspace_inventory_name)
                )
                workspace_inventory_annotations_for_partial_reconciliation = deep_sort_and_symbolize_hashes(
                  workspace_inventory_annotations.merge(partial_reconcile_annotation)
                )

                agent_labels = workspaces_agent_config.labels
                labels = agent_labels.merge({ "agent.gitlab.com/id": workspaces_agent_id.to_s })
                # TODO: Unconditionally add this label in https://gitlab.com/gitlab-org/gitlab/-/issues/535197
                labels["workspaces.gitlab.com/id"] = workspace_id.to_s if shared_namespace.present?

                scripts_configmap_name = "#{workspace_name}-scripts-configmap"

                context.merge({
                  # Please keep alphabetized
                  allow_privilege_escalation: workspaces_agent_config.allow_privilege_escalation,
                  common_annotations: common_annotations,
                  common_annotations_for_partial_reconciliation: common_annotations_for_partial_reconciliation,
                  default_resources_per_workspace_container: default_resources_per_workspace_container,
                  default_runtime_class: workspaces_agent_config.default_runtime_class,
                  domain_template: domain_template,
                  env_secret_name: "#{workspace_name}#{ENV_VAR_SECRET_SUFFIX}",
                  file_secret_name: "#{workspace_name}#{FILE_SECRET_SUFFIX}",
                  gitlab_workspaces_proxy_namespace: workspaces_agent_config.gitlab_workspaces_proxy_namespace,
                  image_pull_secrets: deep_sort_and_symbolize_hashes(workspaces_agent_config.image_pull_secrets),
                  labels: deep_sort_and_symbolize_hashes(labels),
                  max_resources_per_workspace: max_resources_per_workspace,
                  network_policy_egress: deep_sort_and_symbolize_hashes(workspaces_agent_config.network_policy_egress),
                  network_policy_enabled: workspaces_agent_config.network_policy_enabled,
                  replicas: workspace_desired_state_is_running ? 1 : 0,
                  scripts_configmap_name: scripts_configmap_name,
                  secrets_inventory_annotations: secrets_inventory_annotations,
                  secrets_inventory_name: secrets_inventory_name,
                  shared_namespace: shared_namespace,
                  use_kubernetes_user_namespaces: workspaces_agent_config.use_kubernetes_user_namespaces,
                  workspace_inventory_annotations: workspace_inventory_annotations,
                  workspace_inventory_annotations_for_partial_reconciliation:
                    workspace_inventory_annotations_for_partial_reconciliation,
                  workspace_inventory_name: workspace_inventory_name
                }).sort.to_h
              end
              # rubocop:enable Metrics/MethodLength

              # @param [Array, Hash] collection
              # @return [Array, Hash]
              def self.deep_sort_and_symbolize_hashes(collection)
                collection_to_return = Gitlab::Utils.deep_sort_hashes(collection)

                # NOTE: deep_symbolize_keys! is not available on Array, so we wrap the collection in a
                #       Hash in case it is an Array.
                { to_symbolize: collection_to_return }.deep_symbolize_keys!
                collection_to_return
              end

              private_class_method :deep_sort_and_symbolize_hashes
            end
          end
        end
      end
    end
  end
end
