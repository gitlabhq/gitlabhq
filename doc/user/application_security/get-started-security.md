---
stage: DevSecOps
group: Technical writing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Get started with GitLab application security **(ULTIMATE)**

Complete the following steps to get the most from GitLab application security tools.

1. Enable [Secret Detection](secret_detection/index.md) scanning for your default branch.
1. Enable [Dependency Scanning](dependency_scanning/index.md) for your default branch so you can start identifying existing
   vulnerable packages in your codebase.
1. Add security scans to feature branch pipelines. The same scans should be enabled as are running
   on your default branch. Subsequent scans will show only new vulnerabilities by comparing the feature branch to the default branch results.
1. Let your team get comfortable with [vulnerability reports](vulnerability_report/index.md) and
   establish a vulnerability triage workflow.
1. Consider creating [labels](../project/labels.md) and [issue boards](../project/issue_board.md) to
   help manage issues created from vulnerabilities. Issue boards allow all stakeholders to have a
   common view of all issues.
1. Create a [scan result policy](policies/index.md) to limit new vulnerabilities from being merged
   into your default branch.
1. Monitor the [Security Dashboard](security_dashboard/index.md) trends to gauge success in
   remediating existing vulnerabilities and preventing the introduction of new ones.
1. Enable other scan types such as [SAST](sast/index.md), [DAST](dast/index.md),
   [Fuzz testing](coverage_fuzzing/index.md), or [Container Scanning](container_scanning/index.md).
   Be sure to add the same scan types to both feature pipelines and default branch pipelines.
1. Use [Compliance Pipelines](../../user/project/settings/index.md#compliance-pipeline-configuration)
   or [Scan Execution Policies](policies/scan-execution-policies.md) to enforce required scan types
   and ensure separation of duties between security and engineering.
1. Consider enabling [Review Apps](../../development/testing_guide/review_apps.md) to allow for DAST
   and [Web API fuzzing](api_fuzzing/index.md) on ephemeral test environments.
1. Enable [operational container scanning](../../user/clusters/agent/vulnerabilities.md) to scan
   container images in your production cluster for security vulnerabilities.
