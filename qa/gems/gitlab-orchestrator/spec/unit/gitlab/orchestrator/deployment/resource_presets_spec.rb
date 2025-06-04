# frozen_string_literal: true

RSpec.describe Gitlab::Orchestrator::Deployment::ResourcePresets do
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
            requests: { cpu: "900m", memory: "2Gi" },
            limits: { cpu: "900m", memory: "2Gi" }
          },
          hpa: {
            cpu: { targetAverageValue: "800m" }
          }
        },
        kas: {
          minReplicas: 1,
          resources: {
            requests: { cpu: "40m", memory: "96Mi" },
            limits: { cpu: "40m", memory: "96Mi" }
          }
        },
        "gitlab-shell": {
          minReplicas: 1,
          resources: {
            requests: { cpu: "30m", memory: "16Mi" }
          }
        },
        gitaly: {
          resources: {
            requests: { cpu: "300m", memory: "300Mi" },
            limits: { cpu: "300m", memory: "300Mi" }
          }
        },
        toolbox: {
          resources: {
            requests: { cpu: "50m", memory: "128Mi" }
          }
        }
      },
      registry: {
        resources: {
          requests: { cpu: "40m", memory: "96Mi" },
          limits: { cpu: "40m", memory: "96Mi" }
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
          requests: { cpu: "30m", memory: "32Mi" },
          limits: { cpu: "30m", memory: "32Mi" }
        }
      },
      "nginx-ingress": {
        controller: {
          resources: {
            requests: { cpu: "30m", memory: "256Mi" },
            limits: { cpu: "30m", memory: "256Mi" }
          }
        }
      },
      postgresql: {
        primary: {
          resources: {
            requests: { cpu: "400m", memory: "1Gi" },
            limits: { cpu: "400m", memory: "1Gi" }
          }
        }
      },
      redis: {
        master: {
          resources: {
            requests: { cpu: "50m", memory: "16Mi" },
            limits: { cpu: "50m", memory: "16Mi" }
          }
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
            requests: { cpu: 3, memory: "5Gi" },
            limits: { cpu: 3, memory: "7Gi" }
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
            requests: { cpu: "60m", memory: "96Mi" },
            limits: { cpu: "60m", memory: "96Mi" }
          },
          hpa: {
            cpu: {
              targetType: "Utilization",
              targetAverageUtilization: 90
            }
          }
        },
        "gitlab-shell": {
          minReplicas: 1,
          resources: {
            requests: { cpu: "60m", memory: "32Mi" }
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
            requests: { cpu: "400m", memory: "384Mi" },
            limits: { cpu: "400m", memory: "384Mi" }
          }
        },
        toolbox: {
          resources: {
            requests: { cpu: "50m", memory: "128Mi" }
          }
        }
      },
      registry: {
        resources: {
          requests: { cpu: "50m", memory: "128Mi" },
          limits: { cpu: "50m", memory: "128Mi" }
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
          requests: { cpu: "50m", memory: "32Mi" },
          limits: { cpu: "50m", memory: "32Mi" }
        }
      },
      "nginx-ingress": {
        controller: {
          resources: {
            requests: { cpu: "30m", memory: "256Mi" },
            limits: { cpu: "30m", memory: "256Mi" }
          }
        }
      },
      postgresql: {
        primary: {
          resources: {
            requests: { cpu: "600m", memory: "1536Mi" },
            limits: { cpu: "600m", memory: "1536Mi" }
          }
        }
      },
      redis: {
        master: {
          resources: {
            requests: { cpu: "100m", memory: "16Mi" },
            limits: { cpu: "100m", memory: "16Mi" }
          }
        }
      }
    })
  end
end
