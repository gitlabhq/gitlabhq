---
stage: Software Supply Chain Security
group: Authentication
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Compromised password detection development
---

For information on this feature that are not development-specific, see the [feature documentation](../security/compromised_password_detection.md).

## CloudFlare

The CloudFlare [leaked credentials detection](https://developers.cloudflare.com/waf/detections/leaked-credentials/) feature can detect when a request contains compromised credentials, and passes information to the application in the `Exposed-Credential-Check` header through a [managed transform](https://developers.cloudflare.com/rules/transform/managed-transforms/reference/#add-leaked-credentials-checks-header).

GitLab team members can find the CloudFlare Terraform configuration in the GitLab.com infrastructure configuration management repository: `https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt`

## Additional resources

<!-- markdownlint-disable MD044 -->
The [Authentication group](https://handbook.gitlab.com/handbook/engineering/development/sec/software-supply-chain-security/authentication/) owns the compromised password detection feature. GitLab team members can join their channel on Slack: [#g_sscs_authentication](https://gitlab.slack.com/archives/CLM1D8QR0).
<!-- markdownlint-enable MD044 -->
