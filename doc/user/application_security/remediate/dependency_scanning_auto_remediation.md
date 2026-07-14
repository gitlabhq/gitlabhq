---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dependency scanning auto-remediation
description: Automatically open merge requests to fix vulnerable dependencies.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/17403) in GitLab 19.0
  as an [experiment](../../../policy/development_stages_support.md#experiment)
  [with a feature flag](../../../administration/feature_flags/_index.md) named
  `dependency_management_auto_remediation`. Disabled by default.
- [Moved](https://gitlab.com/groups/gitlab-org/-/work_items/604588) to
  [beta](../../../policy/development_stages_support.md#beta) in GitLab 19.2. The
  `dependency_management_auto_remediation` feature flag is enabled by default.
- Agentic breaking-change resolution
  [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/603392) in GitLab 19.2
  [with a feature flag](../../../administration/feature_flags/_index.md) named
  `enable_dependency_bump_breaking_changes`. Disabled by default.

{{< /history >}}

Dependency scanning auto-remediation opens a merge request to bump a vulnerable dependency
to a non-vulnerable version when one is available. A service account creates the
merge request without any human input, which then goes through the standard review and approval
process.

In beta, dependency scanning auto-remediation supports two independently configurable capabilities:

- Dependency version bumps: GitLab opens merge requests that update the vulnerable dependency.
- Agentic breaking-change resolution: When a version bump causes a pipeline failure due to a
  breaking change, GitLab Duo attempts to resolve it. For more information, see
  [enable agentic breaking-change resolution](#enable-agentic-breaking-change-resolution).

For the generally available roadmap, see [epic 19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244).

## Turn on dependency scanning auto-remediation

Prerequisites:

- The `dependency_management_auto_remediation`
  [feature flag](../../../administration/feature_flags/_index.md) must be enabled for the project.
  This flag is enabled by default in GitLab 19.2.
- [Dependency scanning](../dependency_scanning/_index.md) must be enabled
  and producing results.
- The project must use a
  [supported package manager](#supported-package-managers).
- A dependency scanning auto-remediation profile must be attached to the project. For
  instructions, see [dependency scanning auto-remediation profile](../configuration/security_configuration_profiles.md#dependency-scanning-auto-remediation-profile).

To trigger vulnerability detection and auto-remediation, run a pipeline.
Dependency scanning auto-remediation triggers automatically when GitLab detects vulnerabilities
with available fixes.

## How dependency version bumps work

The dependency scanning auto-remediation profile controls this behavior. With the default
profile:

- Severity threshold: GitLab remediates vulnerabilities at or above `high` severity.
- Cooldown period: GitLab excludes fix versions released in the last seven days.
- Upgrade policy: GitLab proposes only patch and minor version bumps, unless
  [agentic breaking-change resolution](#enable-agentic-breaking-change-resolution) is enabled.
- Open merge request limit: A maximum of 10 auto-remediation merge requests can be open
  per project at a time. GitLab does not create new merge requests until existing ones are
  merged or closed.

After each pipeline, GitLab checks dependency scan results against these values. For each
eligible vulnerability:

1. GitLab determines the nearest non-breaking upgrade path.
1. A service account opens a merge request that updates the relevant manifest file.
1. GitLab assigns an active Maintainer of the project as a reviewer. If no active Maintainer
   exists, the merge request stays open without a reviewer.
1. The merge request goes through your project's standard approval workflow.

During beta, GitLab processes three vulnerabilities at a time, starting
with the highest severity finding.

## Enable agentic breaking-change resolution

When a version bump causes a pipeline failure because of a breaking change, GitLab Duo can attempt
to resolve the breaking change automatically. This capability is separate from the dependency
version bump capability and has its own toggle.

Prerequisites:

- You must have [GitLab Duo](../../../user/gitlab_duo/_index.md) available for the project.
- The `enable_dependency_bump_breaking_changes`
  [feature flag](../../../administration/feature_flags/_index.md) must be enabled for the
  project's root namespace.

To enable agentic breaking-change resolution, use the
[Projects API](../../../api/projects.md#update-a-project) to set
`duo_dependency_bump_breaking_changes_enabled` to `true` for the project.

## Configure scheduler concurrency

Administrators can limit how many auto-remediation scheduler jobs
run concurrently across the Sidekiq fleet. Use the
`security_update_scheduler_max_concurrency`
[application setting](../../../api/settings.md) to set the cap. The default is `30`,
and the value is capped at `200`. Set the value to `0` to pause scheduling.

## Supported package managers

Dependency scanning auto-remediation supports the following package managers:

| Language                | Package Manager                     | Files                                                                          |
| ----------------------- | ------------------------------------ | ------------------------------------------------------------------------------ |
| Ruby                    | Bundler                             | `Gemfile`, `Gemfile.lock`                                                      |
| Java                    | Maven                               | `pom.xml`                                                                      |
| Java                    | Gradle                              | `build.gradle`, `build.gradle.kts`                                             |
| Python                  | pip, pipenv, poetry, setuptools, uv | `requirements.txt`, `Pipfile`, `pyproject.toml`, `setup.py`, `uv.lock`         |
| JavaScript / TypeScript | npm, yarn, pnpm, bun                | `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lock` |

Support for additional ecosystems is proposed in
[epic 19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244).

## Known issues

During the beta phase:

- Cooldown period: GitLab does not propose a fix version released in the last
  seven days, to reduce the risk of remediating to a version that is later found
  to be broken or malicious.
- Version bump scope: Only patch and minor version bumps are proposed. Major version upgrades,
  which are more likely to introduce breaking changes, are not attempted unless agentic
  breaking-change resolution is enabled.
- One vulnerability per pipeline run: Each pipeline run targets a single
  vulnerability with an available fix. Batching multiple fixes into one merge request
  is proposed in [epic 19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244).
- No fix available: If no non-breaking fix version exists for a vulnerability,
  no merge request is created for that finding.
