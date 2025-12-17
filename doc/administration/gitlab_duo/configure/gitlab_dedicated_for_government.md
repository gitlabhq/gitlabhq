---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Ensure GitLab Duo is configured and operating correctly on GitLab Dedicated for Government.
title: Configure GitLab Duo on GitLab Dedicated for Government
gitlab_dedicated: yes
---

{{< details >}}

- Offering: GitLab Dedicated for Government

{{< /details >}}

For GitLab Dedicated for Government, you must use
GitLab Duo Self-Hosted with FedRAMP-approved models.
The cloud-based AI Gateway and vendor models are not available for GitLab Dedicated for Government.

## Prerequisites

- [Turn on beta and experimental features](../../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- [Turn off Silent Mode](../../silent_mode/_index.md#turn-off-silent-mode).
- Allow outbound connections to the self-hosted AI Gateway by
  [creating a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)
  to request an opening to your AI Gateway URL.

The GitLab Duo Agent Platform features are disabled with
[feature flags](../../../subscriptions/gitlab_dedicated/_index.md#feature-flags) and are not supported
on GitLab Dedicated for Government.

## Set up GitLab Duo Self-Hosted

For GitLab Dedicated for Government, you must have a
fully self-hosted configuration with FedRAMP-approved models.

For more information, see [set up a GitLab Duo Self-Hosted infrastructure](../../gitlab_duo_self_hosted/_index.md#set-up-a-gitlab-duo-self-hosted-infrastructure).

## Related topics

- [Supported models and hardware requirements](../../gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md)
- [Troubleshooting GitLab Duo Self-Hosted](../../gitlab_duo_self_hosted/troubleshooting.md)
- [Run a health check for GitLab Duo](gitlab_self_managed.md#run-a-health-check-for-gitlab-duo)
