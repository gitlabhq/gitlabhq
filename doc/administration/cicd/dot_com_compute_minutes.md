---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure cost factor settings for compute minutes on GitLab.com.
title: Compute minutes administration for GitLab.com
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

GitLab.com administrators have additional controls over compute minutes beyond what is
available for [GitLab Self-Managed](compute_minutes.md).

## Set cost factors

Prerequisites:

- You must be an administrator for GitLab.com.

To set cost factors for a runner:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **CI/CD > Runners**.
1. For the runner you want to update, select **Edit** ({{< icon name="pencil" >}}).
1. In the **Public projects compute cost factor** text box, enter the public cost factor.
1. In the **Private projects compute cost factor** text box, enter the private cost factor.
1. Select **Save changes**.

## Reduce cost factors for community contributions

When the `ci_minimal_cost_factor_for_gitlab_namespaces` feature flag is enabled for a namespace,
merge request pipelines from forks that target projects in the enabled namespace use a reduced cost factor.
This ensures community contributions don't consume excessive compute minutes.

Prerequisites:

- You must be able to control feature flags.
- You must have the namespace ID for which you want to enable reduced cost factors.

To enable a namespace to use a reduced cost factor:

1. [Enable the feature flag](../feature_flags.md#how-to-enable-and-disable-features-behind-flags) `ci_minimal_cost_factor_for_gitlab_namespaces` for the namespace ID you want to include.

This feature is recommended for use on GitLab.com only. Community contributors should use
community forks for contributions to avoid accumulating minutes when running pipelines
that are not in a merge request targeting a GitLab project.
