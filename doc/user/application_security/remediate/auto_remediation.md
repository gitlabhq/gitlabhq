---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Auto remediation
description: Automatically open merge requests to fix vulnerable dependencies.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/17403) in GitLab 19.0
  as an [experiment](../../../policy/development_stages_support.md#experiment)
  [with a feature flag](../../../administration/feature_flags/_index.md) named
  `dependency_management_auto_remediation`. Disabled by default.

{{< /history >}}

Auto remediation automatically opens a merge request to bump a vulnerable dependency
to a non-vulnerable version when one is available. A service account creates the
merge request without any human input, which then goes through the standard review and approval
process.

For the beta roadmap and planned improvements, see
[epic 18236](https://gitlab.com/groups/gitlab-org/-/work_items/18236).

## Turn on auto remediation

Prerequisites:

- You must have at least one Maintainer for the project.
- The `dependency_management_auto_remediation`
  [feature flag](../../../administration/feature_flags/_index.md) must be
  enabled.
- [Dependency scanning](../dependency_scanning/_index.md) must be enabled
  and producing results.
- The project must use a
  [supported package manager](#supported-package-managers).

To trigger vulnerability detection and auto remediation, run a pipeline.
Auto remediation triggers automatically when vulnerabilities with available fixes are detected.

## How auto remediation works

After each pipeline, GitLab checks dependency scan results for
vulnerabilities with known fix versions. For each eligible vulnerability:

1. GitLab determines the nearest non-breaking upgrade path (patch or minor version bump).
1. A service account opens a merge request that updates the relevant manifest file.
1. The merge request goes through your project's standard approval workflow.

During the experiment phase, GitLab processes three vulnerabilities at a time, starting
with the highest severity finding.

## Supported package managers

Auto remediation supports the following package managers:

| Language | Package Manager | Files                     |
| -------- | --------------- | ------------------------- |
| Ruby     | Bundler         | `Gemfile`, `Gemfile.lock` |

Support for additional ecosystems is planned. For details, see
[epic 21643](https://gitlab.com/groups/gitlab-org/-/work_items/21643).

## Known issues

During the experiment phase:

- Open merge request limit: A maximum of three auto-remediation merge requests can
  be open per project. New merge requests are not created until
  existing ones are merged or closed.
- Version bump scope: Only patch and minor version bumps are proposed.
  Major version upgrades, which may introduce breaking changes, are not attempted.
- One vulnerability per pipeline run: Each pipeline run targets a single
  vulnerability with an available fix. Batching multiple fixes into one merge request
  is planned for beta.
- No fix available: If no non-breaking fix version exists for a vulnerability,
  no merge request is created for that finding.
