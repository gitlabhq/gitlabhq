---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Application security
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab can check your application for security vulnerabilities including:

- Unauthorized access.
- Data leaks.
- Denial of Service (DoS) attacks.

For a click-through demo, see [Integrating security to the pipeline](https://gitlab.navattic.com/gitlab-scans).
<!-- Demo published on 2024-01-15 -->

For details of how vulnerabilities are detected throughout your application's development lifecycle
see [Detect](detect/_index.md).

Statistics and details on vulnerabilities are included in the merge request. Providing
actionable information _before_ changes are merged enables you to be proactive.

To help with the task of managing and addressing vulnerabilities, GitLab provides a security
dashboard you can access from your project or group. For more details, see
[Security Dashboard](security_dashboard/_index.md).

## Data privacy

Concerning data privacy in the domain of security scanners, GitLab processes the source code and performs analysis locally on the GitLab Runner. No data is transmitted outside GitLab infrastructure (server and runners).

Our scanners access the internet only to download the latest sets of signatures, rules, and patches. If you prefer the scanners do not access the internet, consider using an [offline environment](offline_deployments/_index.md).

## Vulnerability scanner maintenance

The following vulnerability scanners and their databases are regularly updated:

| Secure scanning tool                                            | Vulnerabilities database updates |
|:----------------------------------------------------------------|:---------------------------------|
| [Container Scanning](container_scanning/_index.md)            | A job runs on a daily basis to build new images with the latest vulnerability database updates from the upstream scanner. GitLab monitors this job through an internal alert that tells the engineering team when the database becomes more than 48 hours old. For more information, see the [Vulnerabilities database update](container_scanning/_index.md#vulnerabilities-database). |
| [Dependency Scanning](dependency_scanning/_index.md)          | Relies on the [GitLab Advisory Database](gitlab_advisory_database/_index.md) which is updated on a daily basis using data from the National Vulnerability Database (NVD) and the GitHub Advisory Database. |
| [Dynamic Application Security Testing (DAST)](dast/_index.md) | [DAST](dast/browser/_index.md) analyzer is updated on a periodic basis. |
| [Secret Detection](secret_detection/pipeline/_index.md#detected-secrets) | GitLab maintains the [detection rules](secret_detection/pipeline/_index.md#detected-secrets) and [accepts community contributions](secret_detection/pipeline/_index.md#add-new-patterns). The scanning engine is updated at least once per month if a relevant update is available. |
| [Static Application Security Testing (SAST)](sast/_index.md)  | The source of scan rules depends on which [analyzer](sast/analyzers.md) is used for each [supported programming language](sast/_index.md#supported-languages-and-frameworks). GitLab maintains a ruleset for the Semgrep-based analyzer and updates it regularly based on internal research and user feedback. For other analyzers, the ruleset is sourced from the upstream open-source scanner. Each analyzer is updated at least once per month if a relevant update is available. |

In versions of GitLab that use the same major version of the analyzer, you do not have to update
them to benefit from the latest vulnerabilities definitions. The security tools are released as
Docker images. The vendored job definitions that enable them use major release tags according to
[semantic versioning](https://semver.org/). Each new release of the tools overrides these tags.
Although in a major analyzer version you automatically get the latest versions of the scanning
tools, there are some [known issues](https://gitlab.com/gitlab-org/gitlab/-/issues/9725) with this
approach.

NOTE:
To get the most updated vulnerability information on existing vulnerabilities you may need to re-run the default branch's pipeline.

## Security scanning

For security scans that run in a CI/CD pipeline, the results are determined by:

- Which security scanning jobs run in the pipeline.
- Each job's status.
- Each job's output.

### Security jobs in your pipeline

The security scanning jobs that run in a CI/CD pipeline are determined by the following criteria:

1. Inclusion of security scanning templates

   The selection of security scanning jobs is first determined by which templates are included.
   Templates can be included by using AutoDevOps, a scan execution policy, or the
   `.gitlab-ci.yml` configuration file.

1. Evaluation of rules

   Each template has defined [rules](../../ci/yaml/_index.md#rules) which determine if the analyzer
   is run.

   For example, the Secret Detection template includes the following rule. This rule states that
   secret detection should be run in branch pipelines. In the case of a merge request pipeline,
   secret detection is not run.

   ```yaml
   rules:
     - if: $CI_COMMIT_BRANCH
   ```

1. Analyzer logic

   If the template's rules dictate that the job is to be run, a job is created in the pipeline stage
   specified in the template. However, each analyzer has its own logic which determines if the
   analyzer itself is to be run.

   For example, if dependency scanning doesn't detect supported files at the default depth, the
   analyzer is not run and no artifacts are output.

After completing successfully, each job outputs artifacts. These artifacts are processed and the
results are available in GitLab. Results are shown only if all jobs are finished, including manual
ones. Additionally for some features, results are shown only if the pipeline runs on the default branch.

#### Job status

Jobs pass if they are able to complete a scan. A _pass_ result does not indicate if they did, or did not, identify findings. The only exception is coverage fuzzing, which fails if it identifies findings.

Jobs fail if they are unable to complete a scan. You can view the pipeline logs for more information.

All jobs are permitted to fail by default. This means that if they fail, it does not fail the pipeline.

If you want to prevent vulnerabilities from being merged, you should do this by adding [Security Approvals in Merge Requests](#security-approvals-in-merge-requests) which prevents unknown, high or critical findings from being merged without an approval from a specific group of people that you choose.

We do not recommend changing the job [`allow_failure` setting](../../ci/yaml/_index.md#allow_failure) as that fails the entire pipeline.

#### Job artifacts

A security scan job may generate one or more artifacts. From GitLab 17.0, these artifacts are
restricted to the [`developer` role](../permissions.md#roles).

The [security report](../../development/integrations/secure.md#report) artifact generated by the secure analyzer contains all findings it discovers on the target branch, regardless of whether they were previously found, dismissed, or completely new (it puts in everything that it finds).

## Security approvals in merge requests

> - [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/357300) the Vulnerability-Check feature in GitLab 15.0.
> - [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/397067) the License-Check feature in GitLab 16.0.

You can enforce an additional approval for merge requests that would introduce one of the following
security issues:

- A security vulnerability. For more details, read [Merge request approval policies](policies/merge_request_approval_policies.md).

## Self managed installation options

For self managed installations, you can choose to run most of the GitLab security scanners even when [not connected to the internet](offline_deployments/_index.md).

Self managed installations can also run the security scanners on a GitLab Runner [running inside OpenShift](../../install/openshift_and_gitlab/_index.md).

## Security report validation

GitLab 15.0 enforces validation of the security report artifacts before ingesting the vulnerabilities.
This prevents ingestion of broken vulnerability data into the database. GitLab validates the
artifacts against the [report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/tree/master/dist),
according to the schema version declared in the report.

The pipeline's **Security** tab lists any report artifacts that failed validation, and the
validation error message.

Validation depends on the schema version declared in the security report artifact:

- If your security report specifies a supported schema version, GitLab uses this version to validate.
- If your security report uses a deprecated version, GitLab attempts validation against that version and adds a deprecation warning to the validation result.
- If your security report uses a supported MAJOR-MINOR version of the report schema but the PATCH version doesn't match any vendored versions, GitLab attempts to validate it against latest vendored PATCH version of the schema.
  - Example: security report uses version 14.1.1 but the latest vendored version is 14.1.0. GitLab would validate against schema version 14.1.0.
- If your security report uses a version that is not supported, GitLab attempts to validate it against the earliest schema version available in your installation but doesn't ingest the report.
- If your security report does not specify a schema version, GitLab attempts to validate it against the earliest schema version available in GitLab. Because the `version` property is required, validation always fails in this case, but other validation errors may also be present.

You can always find supported and deprecated schema versions in the [source code](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/parsers/security/validators/schema_validator.rb).

## Security scanning configuration tips

Each GitLab security scanning tool has a default
[CI/CD configuration file](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Security),
also known as a _template_.

When customizing the configuration:

- [Include](../../ci/yaml/_index.md#include) the scanning tool's CI/CD template. Don't _copy_ the content
  of the template.
- Use the [stable](../../development/cicd/templates.md#stable-version) version of each template
  for production workflows. The stable version changes less often, and breaking changes are only
  made between major GitLab versions. The [latest](../../development/cicd/templates.md#latest-version)
  version contains the most recent changes, but may have significant changes between minor GitLab versions.
- Only override values in the template as needed. All other values are inherited from the template.

### Enforce scan execution

Security and compliance teams must ensure that security scans:

- Run on a regular basis for all projects.
- Can't be disabled by developers.

GitLab provides two methods of accomplishing this, each with advantages and disadvantages.

- [Compliance framework pipelines](../group/compliance_pipelines.md)
  are recommended when:

  - Scan execution enforcement is required for any scanner that uses a GitLab template, such as SAST IaC, DAST, Dependency Scanning,
    API Fuzzing, or Coverage-guided Fuzzing.
  - Scan execution enforcement is required for scanners external to GitLab.
  - Scan execution enforcement is required for custom jobs other than security scans.

- [Scan execution policies](policies/scan_execution_policies.md)
  are recommended when:

  - Scan execution enforcement is required for DAST which uses a DAST site or scan profile.
  - Scan execution enforcement is required for SAST, SAST IaC, Secret Detection, Dependency Scanning, or Container Scanning with project-specific
    variable customizations. To accomplish this, users must create a separate security policy per project.
  - Scans are required to run on a regular, scheduled cadence.

- Either solution can be used equally well when:

  - Scan execution enforcement is required for Container Scanning with no project-specific variable
    customizations.

Additional details about the differences between the two solutions are outlined below:

| | Compliance Framework Pipelines | Scan Execution Policies |
| ------ | ------ | ------ |
| **Flexibility** | Supports anything that can be done in a CI file. | Limited to only the items for which GitLab has explicitly added support. DAST, SAST, SAST IaC, Secret Detection, Dependency Scanning, and Container Scanning scans are supported. |
| **Usability** | Requires knowledge of CI YAML. | Follows a `rules` and `actions`-based YAML structure. |
| **Inclusion in CI pipeline** | The compliance pipeline is executed instead of the project's `.gitlab-ci.yml` file. To include the project's `.gitlab-ci.yml` file, use an `include` statement. Defined variables aren't allowed to be overwritten by the included project's YAML file. | Forced inclusion of a new job into the CI pipeline. DAST jobs that must be customized on a per-project basis can have project-level Site Profiles and Scan Profiles defined. To ensure separation of duties, these profiles are immutable when referenced in a scan execution policy. All jobs can be customized as part of the security policy itself with the same variables that are usually available to the CI job. |
| **Schedulable** | Has to be scheduled through a scheduled pipeline on each project. | Can be scheduled natively through the policy configuration itself. |
| **Separation of Duties** | Only group owners can create compliance framework labels. Only project owners can apply compliance framework labels to projects. The ability to make or approve changes to the compliance pipeline definition is limited to individuals who are explicitly given access to the project that contains the compliance pipeline. | Only project owners can define a linked security policy project. The ability to make or approve changes to security policies is limited to individuals who are explicitly given access to the security policy project. |
| **Ability to apply one standard to multiple projects** | The same compliance framework label can be applied to multiple projects inside a group. | The same security policy project can be used for multiple projects across GitLab with no requirement of being located in the same group. |

Feedback is welcome on our vision for [unifying the user experience for these two features](https://gitlab.com/groups/gitlab-org/-/epics/7312)

## Custom security role

You can create a [custom role](../custom_roles.md) for security team members who need access to application security features, such as vulnerability management, security policies, or dependencies. This approach allows organizations to follow the Principle of Least Privilege by providing security team members with the privileges they need without promoting them to Developer or Maintainer on a group or project.

For example, the custom security role may have the following [permissions](../custom_roles/abilities.md):

- Name: Custom Security Role
- Description: Manage vulnerabilities and link security policy projects.
- Base Role: Reporter (or any default role)
- Permissions: `admin_vulnerability`, `read_dependency`, `manage_security_policy_link`
