---
stage: Verify
group: Testing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index
description: "Test your code and display reports in merge requests"
---

# Tests and reports in merge requests **(FREE)**

GitLab has the ability to test the changes included in a feature branch and display reports
or link to useful information directly from merge requests:

| Feature                                                                                                | Description                                                                                                                                                                                               |
|--------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Accessibility Testing](accessibility_testing.md)                                                      | Automatically report A11y violations for changed pages in merge requests.                                                                                                                                |
| [Browser Performance Testing](browser_performance_testing.md) **(PREMIUM)**                            | Quickly determine the browser performance impact of pending code changes.                                                                                                                                         |
| [Load Performance Testing](load_performance_testing.md) **(PREMIUM)**                                  | Quickly determine the server performance impact of pending code changes.                                                                                                                                         |
| [Code Quality](code_quality.md)                                                                        | Analyze your source code quality using the [Code Climate](https://codeclimate.com/) analyzer and show the Code Climate report right in the merge request widget area.                                     |
| [Display arbitrary job artifacts](../../../ci/yaml/index.md#artifactsexpose_as)                       | Configure CI pipelines with the `artifacts:expose_as` parameter to directly link to selected [artifacts](../../../ci/pipelines/job_artifacts.md) in merge requests.                                                |
| [GitLab CI/CD](../../../ci/index.md)                                                                  | Build, test, and deploy your code in a per-branch basis with built-in CI/CD.                                                                                                                              |
| [Unit test reports](../../../ci/unit_test_reports.md)                                                  | Configure your CI jobs to use Unit test reports, and let GitLab display a report on the merge request so that it's easier and faster to identify the failure without having to check the entire job log. |
| [License Compliance](../../compliance/license_compliance/index.md) **(ULTIMATE)**                      | Manage the licenses of your dependencies. |
| [Metrics Reports](../../../ci/metrics_reports.md) **(PREMIUM)**                                        | Display the Metrics Report on the merge request so that it's fast and easy to identify changes to important metrics.                                                                                      |
| [Multi-Project pipelines](../../../ci/pipelines/multi_project_pipelines.md) **(PREMIUM)**                        | When you set up GitLab CI/CD across multiple projects, you can visualize the entire pipeline, including all cross-project interdependencies.                                                              |
| [Pipelines for merge requests](../../../ci/pipelines/merge_request_pipelines.md)                           | Customize a specific pipeline structure for merge requests in order to speed the cycle up by running only important jobs.                                                                                 |
| [Pipeline Graphs](../../../ci/pipelines/index.md#visualize-pipelines)                                      | View the status of pipelines within the merge request, including the deployment process.                                                                                                                  |
| [Test Coverage visualization](test_coverage_visualization.md)                                          | See test coverage results for merge requests, within the file diff.                                                                                                                                       |

## Security Reports **(ULTIMATE)**

In addition to the reports listed above, GitLab can do many types of [Security reports](../../application_security/index.md),
generated by scanning and reporting any vulnerabilities found in your project:

| Feature                                                                                 | Description                                                      |
|-----------------------------------------------------------------------------------------|------------------------------------------------------------------|
| [Container Scanning](../../application_security/container_scanning/index.md)            | Analyze your Docker images for known vulnerabilities.            |
| [Dynamic Application Security Testing (DAST)](../../application_security/dast/index.md) | Analyze your running web applications for known vulnerabilities. |
| [Dependency Scanning](../../application_security/dependency_scanning/index.md)          | Analyze your dependencies for known vulnerabilities.             |
| [Static Application Security Testing (SAST)](../../application_security/sast/index.md)  | Analyze your source code for known vulnerabilities.              |
