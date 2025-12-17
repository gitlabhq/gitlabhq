---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure GitLab Duo for your GitLab instance.
title: Configure GitLab Duo
---

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated for Government

{{< /details >}}

GitLab Duo is an AI-native assistant that helps you across the software development lifecycle.

You can configure GitLab Duo on GitLab Self-Managed and GitLab Dedicated for Government.

## GitLab Self-Managed

For GitLab Self-Managed, you can configure GitLab Duo to use:

- Cloud-based AI Gateway (default): GitLab-hosted AI Gateway with vendor language models.
- Self-hosted models: Your own AI Gateway and language models
  for full control over your data and security.
- Hybrid configuration: Self-hosted models for some features
  and cloud-based models for others.

For more information, see [configure GitLab Duo on GitLab Self-Managed](gitlab_self_managed.md).

## GitLab Dedicated for Government

For GitLab Dedicated for Government, you must use
GitLab Duo Self-Hosted with FedRAMP-approved models.
The cloud-based AI Gateway and vendor models are not available for GitLab Dedicated for Government.

For more information, see
[configure GitLab Duo on GitLab Dedicated for Government](gitlab_dedicated_for_government.md).

## Related topics

- [Summary of GitLab Duo features](../../../user/gitlab_duo/feature_summary.md)
- [Control GitLab Duo availability](../../../user/gitlab_duo/turn_on_off.md)
- [Troubleshooting GitLab Duo](../../../user/gitlab_duo/troubleshooting.md)
