---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Ensure GitLab Duo is configured and operating correctly on GitLab Dedicated for Government.
title: Configure GitLab Duo on GitLab Dedicated for Government
gitlab_dedicated: yes
---

{{< details >}}

- Offering: GitLab Dedicated for Government

{{< /details >}}

For GitLab Dedicated for Government, you must use the GitLab Duo Self-Hosted architecture.
The GitLab-managed AI Gateway and models are not available.

> [!note]
> GitLab Duo Agent Platform features are controlled by feature flags that are disabled
> by default and are not available on GitLab Dedicated for Government.

To set up GitLab Duo Self-Hosted:

1. Ensure [Silent Mode is turned off](../../../administration/silent_mode/_index.md#turn-off-silent-mode).
1. [Install the GitLab AI Gateway](../../../install/install_ai_gateway.md) in your AWS GovCloud (US-West).
   For optimal performance, [co-locate your AI Gateway and instance](../../../install/install_ai_gateway.md#co-locate-your-ai-gateway-and-instance).
   - Use a [FIPS-validated AI Gateway image](../../../install/install_ai_gateway.md#fips-validated-images).
     FIPS-validated images are published in the [container registry](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/9518478?orderBy=PUBLISHED_AT&sort=desc&search%5B%5D=self-hosted).
     Select the latest image tagged with the same GitLab version your instance is running.
   - You can deploy the AI Gateway by using [Docker](../../../install/install_ai_gateway.md#install-by-using-docker) or the [GitLab Helm chart](../../../install/install_ai_gateway.md#install-by-using-helm-chart).
     For more information on each deployment method, see [security updates and image verification](../../../install/install_ai_gateway.md#security-updates-and-image-verification).
1. In the environment where you installed the AI Gateway,
   [configure your network settings](../../../install/install_ai_gateway.md#restrict-network-access)
   to enable access to your instance and selected LLMs.
1. [Configure access to the local AI Gateway](../../gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway).
1. [Add a self-hosted model](../../gitlab_duo_self_hosted/configure_duo_features.md#add-a-self-hosted-model)
   to use with GitLab Duo features.
1. Request that GitLab enable network connectivity from your instance to your self-hosted AI Gateway
   and selected LLMs by [creating a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

## Related topics

- [Supported models and hardware requirements](../../gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md)
- [Troubleshooting GitLab Duo Self-Hosted](../../gitlab_duo_self_hosted/troubleshooting.md)
- [Run a health check for GitLab Duo](_index.md#run-a-health-check-for-gitlab-duo)
