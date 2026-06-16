---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Ensure GitLab Duo is configured and operating correctly on GitLab Dedicated for Government.
title: Configure GitLab Duo on GitLab Dedicated for Government
gitlab_dedicated: yes
---

{{< details >}}

- Offering: GitLab Dedicated for Government

{{< /details >}}

For GitLab Dedicated for Government, you must use GitLab Duo Self-Hosted with FedRAMP-approved models.
The cloud-based AI Gateway and vendor models are not available.

> [!note]
> GitLab Duo Agent Platform features are controlled by feature flags that are disabled
> by default and are not available on GitLab Dedicated for Government.

To set up GitLab Duo Self-Hosted:

1. [Turn on beta and experimental features](../../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
1. [Turn off Silent Mode](../../silent_mode/_index.md#turn-off-silent-mode).
1. Allow outbound connections to the self-hosted AI Gateway by
   [creating a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)
   to request an opening to your AI Gateway URL.
1. [Set up your private infrastructure](../../gitlab_duo_self_hosted/_index.md#set-up-private-infrastructure).

## Related topics

- [Supported models and hardware requirements](../../gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md)
- [Troubleshooting GitLab Duo Self-Hosted](../../gitlab_duo_self_hosted/troubleshooting.md)
- [Run a health check for GitLab Duo](_index.md#run-a-health-check-for-gitlab-duo)
