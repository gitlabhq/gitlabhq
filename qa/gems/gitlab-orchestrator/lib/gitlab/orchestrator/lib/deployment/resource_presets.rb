# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Deployment
      # Kubernetes resource request/limit presets optimized for different usecases
      #
      class ResourcePresets
        DEFAULT = "default"
        HIGH = "high"

        class << self
          # Kubernetes resources values for given preset
          #
          # @param [String] preset_name
          # @return [Hash]
          def resource_values(preset_name)
            presets.fetch(preset_name)
          end

          private

          # Different resources presets and replicas count
          #
          # Prefer vertical scaling over hpa for test stability
          #   as waiting for new pods to scale will lead to test flakiness
          # Configure most pods with minReplicas: 1 to simplify debugging
          #   by having less logs files to review
          # To scale webservice and sidekiq, concurrency parameters need to be adjusted together
          #   with cpu and memory values
          # @return [Hash]
          def presets
            @presets ||= {
              # Default preset for local deployments
              DEFAULT => {
                gitlab: {
                  webservice: {
                    workerProcesses: 2,
                    minReplicas: 1,
                    resources: resources("1500m", "3Gi")
                  },
                  sidekiq: {
                    concurrency: 20,
                    minReplicas: 1,
                    resources: resources("900m", "2Gi"),
                    hpa: {
                      cpu: { targetAverageValue: "800m" }
                    }
                  },
                  kas: {
                    minReplicas: 1,
                    resources: resources("40m", "96Mi")
                  },
                  # TODO: if limits are defined, git operations start failing in e2e tests, investigate potential cause
                  # https://gitlab.com/gitlab-org/quality/quality-engineering/team-tasks/-/issues/3699
                  "gitlab-shell": {
                    minReplicas: 1,
                    resources: resources("30m", "16Mi", no_limits: true)
                  },
                  gitaly: {
                    resources: resources("300m", "300Mi")
                  },
                  toolbox: {
                    resources: resources("50m", "128Mi", no_limits: true)
                  }
                },
                registry: {
                  resources: resources("40m", "96Mi"),
                  hpa: {
                    minReplicas: 1,
                    **cpu_utilization
                  }
                },
                minio: {
                  resources: resources("30m", "32Mi")
                },
                "nginx-ingress": {
                  controller: {
                    resources: resources("30m", "256Mi")
                  }
                },
                postgresql: {
                  primary: {
                    resources: resources("400m", "1Gi")
                  }
                },
                redis: {
                  master: {
                    resources: resources("50m", "16Mi")
                  }
                }
              },
              # This preset is optimized for running e2e tests in parallel
              HIGH => {
                gitlab: {
                  webservice: {
                    workerProcesses: 4,
                    minReplicas: 1,
                    # See https://docs.gitlab.com/charts/charts/gitlab/webservice/#memory-requestslimits
                    resources: resources(3, "5Gi", 3, "7Gi"),
                    hpa: cpu_utilization
                  },
                  sidekiq: {
                    concurrency: 30,
                    minReplicas: 1,
                    resources: resources("1200m", "2Gi"),
                    hpa: cpu_utilization
                  },
                  kas: {
                    minReplicas: 1,
                    resources: resources("60m", "96Mi"),
                    hpa: cpu_utilization
                  },
                  # TODO: if limits are defined, git operations start failing in e2e tests, investigate potential cause
                  # https://gitlab.com/gitlab-org/quality/quality-engineering/team-tasks/-/issues/3699
                  "gitlab-shell": {
                    minReplicas: 1,
                    resources: resources("60m", "32Mi", no_limits: true),
                    hpa: cpu_utilization
                  },
                  gitaly: {
                    resources: resources("400m", "384Mi")
                  },
                  # Toolbox create peak load during startup but then consumes very little
                  # Set high limit value but don't request full amount to avoid unnecessary lock
                  toolbox: {
                    resources: resources("50m", "128Mi", no_limits: true)
                  }
                },
                registry: {
                  resources: resources("50m", "128Mi"),
                  hpa: {
                    minReplicas: 1,
                    **cpu_utilization
                  }
                },
                minio: {
                  resources: resources("50m", "32Mi")
                },
                "nginx-ingress": {
                  controller: {
                    resources: resources("30m", "256Mi")
                  }
                },
                postgresql: {
                  primary: {
                    resources: resources("600m", "1536Mi")
                  }
                },
                redis: {
                  master: {
                    resources: resources("100m", "16Mi")
                  }
                }
              }
            }
          end

          # Kubernetes resources configuration
          #
          # Set limits equal to requests by default for simplicity
          #
          # @param [<String, Integer>] cpu_r
          # @param [String] memory_r
          # @param [<String, Integer>] cpu_l
          # @param [String] memory_l
          # @param [Boolean] no_limits if true, skip limit definition
          # @return [Hash]
          def resources(cpu_r, memory_r, cpu_l = nil, memory_l = nil, no_limits: false)
            cpu_l ||= cpu_r
            memory_l ||= memory_r

            {
              requests: {
                cpu: cpu_r,
                memory: memory_r
              }
            }.tap do |definition|
              next if no_limits

              definition[:limits] = {
                cpu: cpu_l,
                memory: memory_l
              }
            end
          end

          # Common hpa cpu utilization config
          #
          # It is recommended to keep value high to avoid scaling entirely
          # To improve test stability, prefer vertical scaling over horizontal
          #
          # @return [Hash]
          def cpu_utilization
            @cpu_utilization ||= {
              cpu: {
                targetType: "Utilization",
                targetAverageUtilization: 90
              }
            }
          end
        end
      end
    end
  end
end
