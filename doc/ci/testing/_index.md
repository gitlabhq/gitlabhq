---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test with GitLab CI/CD
description: Generate test reports, code quality analysis, and security scans that display in merge requests.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use GitLab CI/CD to test changes in feature branches. You can display test reports and
link to important information directly in [merge requests](../../user/project/merge_requests/_index.md).

## Testing and quality reports

You can generate the following reports:

| Feature                                                                                 | Description |
| --------------------------------------------------------------------------------------- | ----------- |
| [Accessibility testing](accessibility_testing.md)                                       | Detect accessibility violations for changed pages. |
| [Browser performance testing](browser_performance_testing.md)                           | Measure browser performance impact of code changes. |
| [Code coverage](code_coverage/_index.md)                                                | View test coverage results, line-by-line coverage in diffs, and overall metrics. |
| [Code quality](code_quality.md)                                                         | Analyze source code quality with Code Climate. |
| [Display arbitrary job artifacts](../yaml/_index.md#artifactsexpose_as)                 | Link to selected job artifacts using `artifacts:expose_as`. |
| [Fail fast testing](fail_fast_testing.md)                                               | Stop pipelines early when RSpec tests fail. |
| [License scanning](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) | Scan and manage dependency licenses. |
| [Load performance testing](load_performance_testing.md)                                 | Measure server performance impact of code changes. |
| [Metrics reports](metrics_reports.md)                                                   | Track custom metrics like memory usage and performance. |
| [Unit test reports](unit_test_reports.md)                                               | View test results and identify failures without checking job logs. |

## Security reports

{{< details >}}

- Tier: Ultimate

{{< /details >}}

You can generate [security reports](../../user/application_security/_index.md) by scanning your project for vulnerabilities:

| Feature                                                                                       | Description |
| --------------------------------------------------------------------------------------------- | ----------- |
| [Container scanning](../../user/application_security/container_scanning/_index.md)            | Scan Docker images for vulnerabilities. |
| [Dynamic application security testing (DAST)](../../user/application_security/dast/_index.md) | Scan running web applications for vulnerabilities. |
| [Dependency scanning](../../user/application_security/dependency_scanning/_index.md)          | Scan dependencies for vulnerabilities. |
| [Static application security testing (SAST)](../../user/application_security/sast/_index.md)  | Scan source code for vulnerabilities. |
