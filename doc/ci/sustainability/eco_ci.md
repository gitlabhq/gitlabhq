---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Measure energy consumption and carbon emissions of your CI/CD pipelines with Eco CI.
title: Eco CI
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Eco CI is a third-party tool that integrates with GitLab CI/CD pipelines.
> GitLab does not maintain or provide support for this tool,
> and makes no representation that this tool satisfies any regulatory or compliance requirements.

[Eco CI](https://www.green-coding.io/products/eco-ci/)
is an open-source tool that measures the energy consumption and carbon emissions of CI/CD pipelines.
It runs as lightweight bash scripts within your pipeline jobs and does not require separate servers or databases.

You place measurement scripts before and after commands in your pipeline jobs.
The tool monitors CPU utilization during command execution and calculates energy
consumption using pre-calculated power curves from the SPECpower database.
It stores all measurement results as text files that you can save as job artifacts to
download and view.
You can also send results to an external dashboard for historical analysis.

## Add Eco CI to your pipeline

Add Eco CI to your pipeline to measure energy consumption and carbon emissions during
job execution.

Eco CI uses the `ECO_CI_LABEL` variable to identify and group your measurements,
so choose a descriptive name that represents your project or pipeline stage.
By default, measurement data is sent to the Green Coding Solutions dashboard for
analysis, but you can set `ECO_CI_SEND_DATA` to `false` to store results locally only.

Prerequisites:

- Pipeline jobs that run on runners with bash support.
- A runner environment with `curl`, `jq`, `awk`, `bash`, `git`, and `coreutils` utilities.

To add Eco CI to your pipeline:

1. In your `.gitlab-ci.yml` file, include the Eco CI template and configure your project identifier:

   ```yaml
   variables:
     ECO_CI_LABEL: "my-project-pipeline"
     ECO_CI_SEND_DATA: "false"

   include:
     - remote: 'https://raw.githubusercontent.com/green-coding-solutions/eco-ci-energy-estimation/main/eco-ci-gitlab.yml'
   ```

1. Add measurement scripts to your jobs:

   ```yaml
   build-job:
     image: node:alpine
     before_script:
       - apk add --no-cache curl jq gawk bash git coreutils
     script:
       - !reference [.start_measurement, script]
       - npm install
       - npm run build
       - npm test
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]
     artifacts:
       paths:
         - eco-ci-output.txt
         - metrics.txt
       expire_in: 1 week
   ```

1. Optional. To measure commands separately, use measurement scripts for each command:

   ```yaml
   build-job:
     image: node:alpine
     before_script:
       - apk add --no-cache curl jq gawk bash git coreutils
     script:
       - !reference [.start_measurement, script]
       - npm install
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]

       - !reference [.start_measurement, script]
       - npm run build
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]

       - !reference [.start_measurement, script]
       - npm test
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]
     artifacts:
       paths:
         - eco-ci-output.txt
         - metrics.txt
       expire_in: 1 week
   ```

## View measurement results

Eco CI stores measurement results in job artifacts that you can access through the
GitLab interface. The measurement results include:

- Energy consumption: Displayed in joules and watts
- Carbon emissions: Estimated emissions in grams of CO₂ equivalent (gCO₂eq)
- Duration: Length of the measured period in seconds
- CPU utilization: Average CPU usage during measurement
- Software Carbon Intensity (SCI): Carbon emissions per pipeline run

To view measurement results:

1. Go to your pipeline.
1. Select the job that includes Eco CI measurements.
1. In the job details, under **Job artifacts**, select **Browse**.
1. Open the `eco-ci-output.txt` file.

Example output:

```plaintext
"build-job: Label: my-project-pipeline: Energy Used [Joules]:" 5.82
"build-job: Label: my-project-pipeline: Avg. CPU Utilization:" 22.69
"build-job: Label: my-project-pipeline: Avg. Power [Watts]:" 1.91
"build-job: Label: my-project-pipeline: Duration [seconds]:" 3.04
----------------
"build-job: Energy [Joules]:" 5.82
"build-job: Avg. CPU Utilization:" 22.69
"build-job: Avg. Power [Watts]:" 1.91
"build-job: Duration [seconds]:" 3.04
----------------
🌳 CO2 Data:
CO₂ from energy is: 0.001944 g
CO₂ from manufacturing (embodied carbon) is: 0.000442 g
Carbon Intensity for this location: 334 gCO₂eq/kWh
SCI: 0.002386 gCO₂eq / pipeline run emitted
```

## Dashboard integration

If you set `ECO_CI_SEND_DATA` to `true`, measurement data is automatically sent to
the [Eco CI metrics dashboard](https://metrics.green-coding.io/ci-index.html).
The dashboard provides historical records, trend analysis, and comparison between pipeline runs.
By default, the dashboards are public and can be viewed by anyone.

You can view energy consumption trends over time, carbon emission patterns,
and compare measurements across different branches, commits, or time periods.
Access the dashboard with your project's `ECO_CI_LABEL` identifier.

### Add a badge to your project

You can display an Eco CI badge in your project's `README.md` file to show energy consumption metrics.

Prerequisites:

- `ECO_CI_SEND_DATA` must be set to `true`.
- At least one pipeline must have run successfully with Eco CI enabled.

To add the badge to the `README.md` file:

1. Copy and paste the following into your `README.md` file:

   ```markdown
   [![Eco CI](https://api.green-coding.io/v1/ci/badge/get?repo=<namespace>/<project>&branch=<branch>&workflow=<project-id>)](https://metrics.green-coding.io/ci.html?repo=<namespace>/<project>&branch=<branch>&workflow=<project-id>)
   ```

1. Replace the placeholders:

   - `<namespace>/<project>` with your GitLab project path (for example, `mygroup/myproject`)
   - `<branch>` with your branch name (for example, `main`)
   - `<project-id>` with your GitLab project ID (for example, `52215136`)

Example:

```markdown
[![Eco CI](https://api.green-coding.io/v1/ci/badge/get?repo=lyspin/eco-ci-demo&branch=main&workflow=52215136)](https://metrics.green-coding.io/ci.html?repo=lyspin/eco-ci-demo&branch=main&workflow=52215136)
```

## Troubleshooting

When you work with Eco CI, you might encounter these issues.

### Error: Date has returned a timestamp that is not accurate to microseconds

You might get an error message:

```shell
ERROR: Date has returned a timestamp that is not accurate to microseconds! You may need to install `coreutils`.
```

This issue occurs when using Alpine Linux or other minimal distributions that don't include GNU `coreutils` by default.

To resolve this issue, install `coreutils`. For example, with Alpine:

```yaml
before_script:
  - apk add --no-cache coreutils
```

### No measurement data appears in artifacts

You don't see the `eco-ci-output.txt` file in your job artifacts.

This issue could be caused by missing artifacts configuration, so ensure
your job contains the correct `artifacts` configuration:

```yaml
artifacts:
  paths:
    - eco-ci-output.txt
    - metrics.txt
```

### Measurements show zero energy consumption

Your `eco-ci-output.txt` file shows values like `Energy [Joules]: 0.00`.

This issue occurs when measurement scripts are placed incorrectly.

To resolve this issue, ensure measurement scripts surround CPU-intensive commands:

```yaml
script:
  - !reference [.start_measurement, script]
  - npm install  # CPU-intensive command
  - npm run build  # CPU-intensive command
  - !reference [.get_measurement, script]
  - !reference [.display_results, script]
```
