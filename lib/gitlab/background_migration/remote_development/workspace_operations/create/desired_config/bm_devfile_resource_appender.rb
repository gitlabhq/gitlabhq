# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module Create
          module DesiredConfig
            # rubocop:disable Metrics/MethodLength -- The original method is copied from ee/lib/remotedevelopment
            # rubocop:disable Metrics/ClassLength -- The original class is copied from ee/lib/remotedevelopment
            class BmDevfileResourceAppender # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
              include BmWorkspaceOperationsConstants

              # @param [Hash] context
              # @return [Hash]
              def self.append(context)
                context => {
                  common_annotations: common_annotations,
                  common_annotations_for_partial_reconciliation: common_annotations_for_partial_reconciliation,
                  desired_config_array: desired_config_array,
                  env_secret_name: env_secret_name,
                  file_secret_name: file_secret_name,
                  gitlab_workspaces_proxy_namespace: gitlab_workspaces_proxy_namespace,
                  image_pull_secrets: image_pull_secrets,
                  labels: labels,
                  max_resources_per_workspace: max_resources_per_workspace,
                  network_policy_egress: network_policy_egress,
                  network_policy_enabled: network_policy_enabled,
                  processed_devfile_yaml: processed_devfile_yaml,
                  scripts_configmap_name: scripts_configmap_name,
                  secrets_inventory_annotations: secrets_inventory_annotations,
                  secrets_inventory_name: secrets_inventory_name,
                  shared_namespace: shared_namespace,
                  workspace_inventory_annotations: workspace_inventory_annotations,
                  workspace_inventory_annotations_for_partial_reconciliation:
                  workspace_inventory_annotations_for_partial_reconciliation,
                  workspace_inventory_name: workspace_inventory_name,
                  workspace_name: workspace_name,
                  workspace_namespace: workspace_namespace
                }

                append_inventory_configmap(
                  desired_config_array: desired_config_array,
                  name: workspace_inventory_name,
                  namespace: workspace_namespace,
                  labels: labels,
                  annotations: common_annotations_for_partial_reconciliation,
                  prepend: true
                )

                append_image_pull_secrets_service_account(
                  desired_config_array: desired_config_array,
                  name: workspace_name,
                  namespace: workspace_namespace,
                  image_pull_secrets: image_pull_secrets,
                  labels: labels,
                  annotations: workspace_inventory_annotations_for_partial_reconciliation
                )

                append_network_policy(
                  desired_config_array: desired_config_array,
                  name: workspace_name,
                  namespace: workspace_namespace,
                  gitlab_workspaces_proxy_namespace: gitlab_workspaces_proxy_namespace,
                  network_policy_enabled: network_policy_enabled,
                  network_policy_egress: network_policy_egress,
                  labels: labels,
                  annotations: workspace_inventory_annotations_for_partial_reconciliation
                )

                append_scripts_resources(
                  desired_config_array: desired_config_array,
                  processed_devfile_yaml: processed_devfile_yaml,
                  name: scripts_configmap_name,
                  namespace: workspace_namespace,
                  labels: labels,
                  annotations: workspace_inventory_annotations_for_partial_reconciliation
                )

                append_inventory_configmap(
                  desired_config_array: desired_config_array,
                  name: secrets_inventory_name,
                  namespace: workspace_namespace,
                  labels: labels,
                  annotations: common_annotations
                )

                append_resource_quota(
                  desired_config_array: desired_config_array,
                  name: workspace_name,
                  namespace: workspace_namespace,
                  labels: labels,
                  annotations: workspace_inventory_annotations,
                  max_resources_per_workspace: max_resources_per_workspace,
                  shared_namespace: shared_namespace
                )

                append_secret(
                  desired_config_array: desired_config_array,
                  name: env_secret_name,
                  namespace: workspace_namespace,
                  labels: labels,
                  annotations: secrets_inventory_annotations
                )

                append_secret(
                  desired_config_array: desired_config_array,
                  name: file_secret_name,
                  namespace: workspace_namespace,
                  labels: labels,
                  annotations: secrets_inventory_annotations
                )

                context.merge({ desired_config_array: desired_config_array })
              end

              # @param [Array] desired_config_array
              # @param [String] name
              # @param [String] namespace
              # @param [Hash<String, String>] labels
              # @param [Hash<String, String>] annotations
              # @param [Boolean] prepend -- If true, prepend the configmap to the desired_config_array
              # @return [void]
              def self.append_inventory_configmap(
                desired_config_array:,
                name:,
                namespace:,
                labels:,
                annotations:,
                prepend: false
              )
                extra_labels = { "cli-utils.sigs.k8s.io/inventory-id": name }

                configmap = {
                  kind: "ConfigMap",
                  apiVersion: "v1",
                  metadata: {
                    name: name,
                    namespace: namespace,
                    labels: labels.merge(extra_labels),
                    annotations: annotations
                  }
                }

                if prepend
                  desired_config_array.prepend(configmap)
                else
                  desired_config_array.append(configmap)
                end

                nil
              end

              # @param [Array] desired_config_array
              # @param [String] name
              # @param [String] namespace
              # @param [Hash] labels
              # @param [Hash] annotations
              # @return [void]
              def self.append_secret(desired_config_array:, name:, namespace:, labels:, annotations:)
                secret = {
                  kind: "Secret",
                  apiVersion: "v1",
                  metadata: {
                    name: name,
                    namespace: namespace,
                    labels: labels,
                    annotations: annotations
                  },
                  data: {}
                }

                desired_config_array.append(secret)

                nil
              end

              # @param [Array] desired_config_array
              # @param [String] gitlab_workspaces_proxy_namespace
              # @param [String] name
              # @param [String] namespace
              # @param [Boolean] network_policy_enabled
              # @param [Array] network_policy_egress
              # @param [Hash] labels
              # @param [Hash] annotations
              # @return [void]
              def self.append_network_policy(
                desired_config_array:,
                name:,
                namespace:,
                gitlab_workspaces_proxy_namespace:,
                network_policy_enabled:,
                network_policy_egress:,
                labels:,
                annotations:
              )
                return unless network_policy_enabled

                egress_ip_rules = network_policy_egress

                policy_types = %w[Ingress Egress]

                proxy_namespace_selector = {
                  matchLabels: {
                    "kubernetes.io/metadata.name": gitlab_workspaces_proxy_namespace
                  }
                }
                proxy_pod_selector = {
                  matchLabels: {
                    "app.kubernetes.io/name": "gitlab-workspaces-proxy"
                  }
                }
                ingress = [{ from: [{ namespaceSelector: proxy_namespace_selector, podSelector: proxy_pod_selector }] }]

                kube_system_namespace_selector = {
                  matchLabels: {
                    "kubernetes.io/metadata.name": "kube-system"
                  }
                }
                egress = [
                  {
                    ports: [{ port: 53, protocol: "TCP" }, { port: 53, protocol: "UDP" }],
                    to: [{ namespaceSelector: kube_system_namespace_selector }]
                  }
                ]
                egress_ip_rules.each do |egress_rule|
                  egress.append(
                    { to: [{ ipBlock: { cidr: egress_rule[:allow], except: egress_rule[:except] } }] }
                  )
                end

                # Use the workspace_id as a pod selector if it is present
                workspace_id = labels.fetch(:"workspaces.gitlab.com/id", nil)
                pod_selector = {}
                # TODO: Unconditionally add this pod selector in https://gitlab.com/gitlab-org/gitlab/-/issues/535197
                if workspace_id.present?
                  pod_selector[:matchLabels] = {
                    "workspaces.gitlab.com/id": workspace_id
                  }
                end

                network_policy = {
                  apiVersion: "networking.k8s.io/v1",
                  kind: "NetworkPolicy",
                  metadata: {
                    annotations: annotations,
                    labels: labels,
                    name: name,
                    namespace: namespace
                  },
                  spec: {
                    egress: egress,
                    ingress: ingress,
                    podSelector: pod_selector,
                    policyTypes: policy_types
                  }
                }

                desired_config_array.append(network_policy)

                nil
              end

              # @param [Array] desired_config_array
              # @param [String] processed_devfile_yaml
              # @param [String] name
              # @param [String] namespace
              # @param [Hash] labels
              # @param [Hash] annotations
              # @return [void]
              def self.append_scripts_resources(
                desired_config_array:,
                processed_devfile_yaml:,
                name:,
                namespace:,
                labels:,
                annotations:
              )
                desired_config_array => [
                  *_,
                  {
                    kind: "Deployment",
                    spec: {
                      template: {
                        spec: {
                          containers: Array => containers,
                          volumes: Array => volumes
                        }
                      }
                    }
                  },
                  *_
                ]

                processed_devfile = YAML.safe_load(processed_devfile_yaml).deep_symbolize_keys.to_h

                devfile_commands = processed_devfile.fetch(:commands)
                devfile_events = processed_devfile.fetch(:events)

                # NOTE: This guard clause ensures we still support older running workspaces which were started before we
                #       added support for devfile postStart events. In that case, we don't want to add any resources
                #       related to the postStart script handling, because that would cause those existing workspaces
                #       to restart because the deployment would be updated.
                return unless devfile_events[:postStart].present?

                BmScriptsConfigmapAppender.append(
                  desired_config_array: desired_config_array,
                  name: name,
                  namespace: namespace,
                  labels: labels,
                  annotations: annotations,
                  devfile_commands: devfile_commands,
                  devfile_events: devfile_events
                )

                BmScriptsVolumeInserter.insert(
                  configmap_name: name,
                  containers: containers,
                  volumes: volumes
                )

                BmKubernetesPoststartHookInserter.insert(
                  containers: containers,
                  devfile_commands: devfile_commands,
                  devfile_events: devfile_events
                )

                nil
              end

              # @param [Array] desired_config_array
              # @param [String] name
              # @param [String] namespace
              # @param [Hash] labels
              # @param [Hash] annotations
              # @param [Hash] max_resources_per_workspace
              # @param [String] shared_namespace
              # @return [void]
              def self.append_resource_quota(
                desired_config_array:,
                name:,
                namespace:,
                labels:,
                annotations:,
                max_resources_per_workspace:,
                shared_namespace:
              )
                return unless max_resources_per_workspace.present?
                return if shared_namespace.present?

                max_resources_per_workspace => {
                  limits: {
                    cpu: limits_cpu,
                    memory: limits_memory
                  },
                  requests: {
                    cpu: requests_cpu,
                    memory: requests_memory
                  }
                }

                resource_quota = {
                  apiVersion: "v1",
                  kind: "ResourceQuota",
                  metadata: {
                    annotations: annotations,
                    labels: labels,
                    name: name,
                    namespace: namespace
                  },
                  spec: {
                    hard: {
                      "limits.cpu": limits_cpu,
                      "limits.memory": limits_memory,
                      "requests.cpu": requests_cpu,
                      "requests.memory": requests_memory
                    }
                  }
                }

                desired_config_array.append(resource_quota)

                nil
              end

              # @param [Array] desired_config_array
              # @param [String] name
              # @param [String] namespace
              # @param [Hash] labels
              # @param [Hash] annotations
              # @param [Array] image_pull_secrets
              # @return [void]
              def self.append_image_pull_secrets_service_account(
                desired_config_array:,
                name:,
                namespace:,
                labels:,
                annotations:,
                image_pull_secrets:
              )
                image_pull_secrets_names = image_pull_secrets.map { |secret| { name: secret.fetch(:name) } }

                workspace_service_account_definition = {
                  apiVersion: "v1",
                  kind: "ServiceAccount",
                  metadata: {
                    name: name,
                    namespace: namespace,
                    annotations: annotations,
                    labels: labels
                  },
                  automountServiceAccountToken: false,
                  imagePullSecrets: image_pull_secrets_names
                }

                desired_config_array.append(workspace_service_account_definition)

                nil
              end

              private_class_method :append_inventory_configmap,
                :append_secret,
                :append_network_policy,
                :append_scripts_resources,
                :append_resource_quota,
                :append_image_pull_secrets_service_account
            end
            # rubocop:enable Metrics/MethodLength
            # rubocop:enable Metrics/ClassLength
          end
        end
      end
    end
  end
end
