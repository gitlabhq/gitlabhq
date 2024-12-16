# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Deployment::ResourcePresets do
  it "returns default resources values preset" do
    expect(described_class.resource_values(described_class::DEFAULT)).to eq({
      gitlab: {
        webservice: {
          workerProcesses: 2,
          minReplicas: 1,
          resources: {
            requests: { cpu: "1500m", memory: "3Gi" },
            limits: { cpu: "1500m", memory: "3Gi" }
          }
        },
        sidekiq: {
          concurrency: 20,
          minReplicas: 1,
          resources: {
            requests: { cpu: "900m", memory: "1.6Gi" },
            limits: { cpu: "900m", memory: "1.6Gi" }
          },
          hpa: {
            cpu: { targetAverageValue: "800m" }
          }
        },
        kas: {
          minReplicas: 1,
          resources: {
            requests: { cpu: "10m", memory: "45Mi" },
            limits: { cpu: "10m", memory: "45Mi" }
          }
        },
        gitlab_shell: {
          minReplicas: 1,
          resources: {
            requests: { cpu: "80m", memory: "16Mi" },
            limits: { cpu: "80m", memory: "16Mi" }
          }
        },
        gitaly: {
          resources: {
            requests: { cpu: "300m", memory: "300Mi" },
            limits: { cpu: "300m", memory: "300Mi" }
          }
        }
      },
      registry: {
        resources: {
          requests: { cpu: "50m", memory: "100Mi" },
          limits: { cpu: "50m", memory: "100Mi" }
        },
        hpa: {
          minReplicas: 1,
          cpu: {
            targetType: "Utilization",
            targetAverageUtilization: 90
          }
        }
      },
      minio: {
        resources: {
          requests: { cpu: "9m", memory: "128Mi" },
          limits: { cpu: "9m", memory: "128Mi" }
        }
      }
    })
  end

  it "returns high resources values preset" do
    expect(described_class.resource_values(described_class::HIGH)).to eq({
      gitlab: {
        webservice: {
          workerProcesses: 4,
          minReplicas: 1,
          resources: {
            requests: { cpu: 3, memory: "4.5Gi" },
            limits: { cpu: 3, memory: "4.5Gi" }
          },
          hpa: {
            cpu: {
              targetType: "Utilization",
              targetAverageUtilization: 90
            }
          }
        },
        sidekiq: {
          concurrency: 30,
          minReplicas: 1,
          resources: {
            requests: { cpu: "1200m", memory: "2Gi" },
            limits: { cpu: "1200m", memory: "2Gi" }
          },
          hpa: {
            cpu: {
              targetType: "Utilization",
              targetAverageUtilization: 90
            }
          }
        },
        kas: {
          minReplicas: 1,
          resources: {
            requests: { cpu: "40m", memory: "64Mi" },
            limits: { cpu: "40m", memory: "64Mi" }
          },
          hpa: {
            cpu: {
              targetType: "Utilization",
              targetAverageUtilization: 90
            }
          }
        },
        gitlab_shell: {
          minReplicas: 1,
          resources: {
            requests: { cpu: "24m", memory: "32Mi" },
            limits: { cpu: "24m", memory: "32Mi" }
          },
          hpa: {
            cpu: {
              targetType: "Utilization",
              targetAverageUtilization: 90
            }
          }
        },
        gitaly: {
          resources: {
            requests: { cpu: "450m", memory: "450Mi" },
            limits: { cpu: "450m", memory: "450Mi" }
          }
        }
      },
      registry: {
        resources: {
          requests: { cpu: "100m", memory: "200Mi" },
          limits: { cpu: "100m", memory: "200Mi" }
        },
        hpa: {
          minReplicas: 1,
          cpu: {
            targetType: "Utilization",
            targetAverageUtilization: 90
          }
        }
      },
      minio: {
        resources: {
          requests: { cpu: "15m", memory: "256Mi" },
          limits: { cpu: "15m", memory: "256Mi" }
        }
      }
    })
  end
end
