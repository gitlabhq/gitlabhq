---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Measure the carbon emissions from your cloud infrastructure and applications with Carmen.
title: Carmen
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Carmen is draft software that has not been approved or adopted by the Green Software Foundation.
> Do not rely on Carmen for any purpose other than review of the current state of development.
> GitLab does not maintain or provide support for this tool,
> and makes no representation that this tool satisfies any regulatory or compliance requirements.
> Carmen is not suitable for corporate ESG reporting, compliance disclosures, or marketing material.

[Carmen](https://github.com/Green-Software-Foundation/if-carmen) (Carbon Measurement Engine)
is an open source tool that measures the carbon emissions from your cloud infrastructure
and applications.

Carmen measures carbon emissions from two sources:

- Infrastructure: Energy consumption and carbon emissions from virtual machines and cloud
  workloads, using VM usage data in CSV format.
- Application: Carbon emissions from individual workloads and pods running in a Kubernetes
  cluster, using Prometheus metrics.

Carmen outputs a CSV report you can use in Grafana, FinOps dashboards, or your own tooling.

## Input data format

The Carmen daemon expects VM usage data in CSV format. For a local file,
point `config.yaml` at the path where your CSV lives. If you use Azure Blob Storage,
configure your storage account in `config.yaml` and Carmen reads the data directly.

The required fields are:

| Field                  | Description                                                    | Example |
| ---------------------- | -------------------------------------------------------------- | ------- |
| `Time`                 | Timestamp in ISO 8601 format.                                  | `2024-10-15T14:30:00Z` |
| `Id`                   | Unique identifier for the VM (controls report granularity).    | `vm-a1b2c3d4` |
| `Size`                 | VM instance size.                                              | `Standard_D4s_v3` |
| `Region`               | Region where the VM is deployed.                               | `eastus` |
| `Service`              | Cloud service or product category.                             | `Compute` |
| `Component`            | Application layer the VM serves.                               | `api-gateway` |
| `Subscription`         | Cloud subscription identifier.                                 | `prod-subscription-001` |
| `Name`                 | Human-readable VM name.                                        | `production-web-01` |
| `Instance`             | Instance identifier for a VM in a deployment group.            | `web-server-03` |
| `Environment`          | Deployment environment.                                        | `production` |
| `Partition`            | Logical partition or tenant.                                   | `team-finance` |
| `AverageCpuPercentage` | Average CPU utilization during the measurement period (0-100). | `45.7`  |
| `DiskSizeGb`           | Total provisioned disk storage in gigabytes.                   | `128`   |

The `Id` field controls report granularity. Each unique value in `Id` generates one component
in the output. Per-VM is typical, but you can use a coarser identifier (per service) or a
finer one depending on the insights you need.

## Add Carmen to your pipeline

You can run Carmen as a CI/CD job to generate a carbon emissions report from your VM usage
data, saved as a pipeline artifact.

Prerequisites:

- Python 3.12, pip, npm, Git, `lsb-release`, and bash in your runner environment.
- VM usage data as a local CSV file in the required format.
  Carmen also supports reading from Azure Blob Storage.
- A `config.yaml` file at a known path.

To add Carmen to your pipeline:

1. In your `.gitlab-ci.yml` file, add a job that installs Carmen and runs the daemon
   against the example data shipped with Carmen:

   ```yaml
   carbon-report:
     image: python:3.12
     before_script:
       - apt-get update && apt-get install -y nodejs npm git lsb-release
       - git clone https://github.com/Green-Software-Foundation/if-carmen.git
       - npm install -g "@grnsft/if@1.0.0" "@grnsft/if-plugins@0.3.2" "@grnsft/if-unofficial-plugins@0.3.1"
       - pip install --upgrade pip && pip install -e $CI_PROJECT_DIR/if-carmen
     script:
       - cd $CI_PROJECT_DIR/if-carmen/example-data && carbon-daemon
     artifacts:
       paths:
         - if-carmen/example-data/output/
       expire_in: 1 week
   ```

1. Run the pipeline and confirm the job produces a `CO2_<date>.csv` file in the artifacts
   with non-zero values in the `EnergykWh` and `TotalCarbonGramsCO2eq` columns.
1. Add a `config.yaml` to your repository that points to your local CSV data:

   ```yaml
   carmen_daemon:
     source:
       type: local
       file_names:
         - "vm_metrics.csv"
       local:
         source_path: "data/vm-metrics"
     upload:
       type: local
       local:
         upload_path: "./output"
   ```

   For Azure Blob Storage, set `source.type` to `azure` and add your Azure storage account settings and credentials.
   For all options, see [Carmen configuration](https://github.com/Green-Software-Foundation/if-carmen/blob/dev/docs/configuration.md).

1. Replace the `script` and `artifacts` sections of your job:

   ```yaml
   script:
     - mkdir -p $CI_PROJECT_DIR/output
     - cd $CI_PROJECT_DIR && carbon-daemon
   artifacts:
     paths:
       - output/
     expire_in: 1 week
   ```

1. Run the pipeline again and confirm the output `CO2_<date>.csv` contains your own data.

## View results

Carmen generates a CSV report with one row per component (VM) per day. The output file
follows the naming pattern `CO2_<date>.csv` and is saved to the path configured in
`upload.local.upload_path`.

To view results:

1. Go to your pipeline.
1. Select the `carbon-report` job.
1. Under **Job artifacts**, select **Browse**.
1. Open the `CO2_<date>.csv` file.

The report includes the following fields:

| Field                         | Description |
| ----------------------------- | ----------- |
| `Date`                        | The 24-hour reporting bucket. |
| `Id`                          | Unique identifier for the component (VM). |
| `Name`                        | Human-readable name of the VM. |
| `EnergykWh`                   | Total energy consumed in kilowatt-hours. |
| `OperationalCarbonGramsCO2eq` | Carbon emissions from energy consumption during operation. |
| `EmbodiedCarbonGramsCO2eq`    | Carbon emissions from hardware manufacturing, transport, and disposal. |
| `TotalCarbonGramsCO2eq`       | Sum of operational and embodied carbon emissions. |
| `CarbonIntensity`             | Carbon intensity of the regional electricity grid (gCO2eq/kWh). |

## Application measurement

For carbon emissions measurement of individual workloads in a Kubernetes cluster, you can
deploy Carmen as a sidecar API service alongside Prometheus. This mode pulls CPU and memory
metrics per pod at configurable intervals.

This deployment requires a Kubernetes cluster with Helm, Prometheus, kube-state-metrics,
and cAdvisor. For more information, see
[Carmen as a Service](https://github.com/Green-Software-Foundation/if-carmen/blob/dev/docs/carmen-as-a-service.md)
in the Carmen repository.

## Troubleshooting

When you work with Carmen, you might encounter the following issues.

### First report output looks incorrect

Your carbon emissions values seem unexpectedly high or low.

This issue occurs when Carmen falls back to the default benchmark hardware configuration
because real VM specs were not supplied.

To resolve this issue, provide real VM specs from your cloud provider's API.

### Output contains only one row per VM

Your report has fewer rows than expected.

This issue occurs when multiple records share the same `Id` value.

To resolve this issue, check the `Id` column in your input CSV.
Each unique value in `Id` generates one component in the output.

### Carmen produces no output

The output directory is empty after running `carbon-daemon`.

This issue can be caused by the Impact Framework not being installed globally, or by
`config.yaml` paths not resolving from the directory where you run `carbon-daemon`.

To resolve this issue:

- Verify that `@grnsft/if` is installed and accessible: `if-run --version`
- Check that paths in `config.yaml` resolve from your working directory.

### Measurements aggregate to daily totals only

You need hourly or sub-daily carbon emissions values.

Carmen only aggregates to daily totals. Hourly resolution is a known limitation.
