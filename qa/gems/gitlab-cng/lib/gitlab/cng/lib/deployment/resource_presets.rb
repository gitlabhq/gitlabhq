# frozen_string_literal: true

module Gitlab
  module Cng
    module Deployment
      # Kubernetes resource request/limit presets optimised for different usecases
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
          # Waiting for new pods to scale will lead to test flakiness and makes log reading harder
          #
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
                    resources: resources("900m", "1.6Gi"),
                    hpa: {
                      cpu: { targetAverageValue: "800m" }
                    }
                  },
                  kas: {
                    minReplicas: 1,
                    resources: resources("10m", "45Mi")
                  },
                  gitlab_shell: {
                    minReplicas: 1,
                    resources: resources("80m", "16Mi")
                  },
                  gitaly: {
                    resources: resources("300m", "300Mi")
                  }
                },
                registry: {
                  resources: resources("50m", "100Mi"),
                  hpa: {
                    minReplicas: 1,
                    **cpu_utilization
                  }
                },
                minio: {
                  resources: resources("9m", "128Mi")
                }
              },
              # This preset is optimised for running e2e tests in parallel
              HIGH => {
                gitlab: {
                  webservice: {
                    workerProcesses: 4,
                    minReplicas: 1,
                    resources: resources(3, "4.5Gi"),
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
                    resources: resources("40m", "64Mi"),
                    hpa: cpu_utilization
                  },
                  gitlab_shell: {
                    minReplicas: 1,
                    resources: resources("24m", "32Mi"),
                    hpa: cpu_utilization
                  },
                  gitaly: {
                    resources: resources("450m", "450Mi")
                  }
                },
                registry: {
                  resources: resources("100m", "200Mi"),
                  hpa: {
                    minReplicas: 1,
                    **cpu_utilization
                  }
                },
                minio: {
                  resources: resources("15m", "256Mi")
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
          # @return [Hash]
          def resources(cpu_r, memory_r, cpu_l = nil, memory_l = nil)
            cpu_l ||= cpu_r
            memory_l ||= memory_r

            {
              requests: {
                cpu: cpu_r,
                memory: memory_r
              },
              limits: {
                cpu: cpu_l,
                memory: memory_l
              }
            }
          end

          # Common hpa cpu utilization config
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
