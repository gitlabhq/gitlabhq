---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting GitLab Duo
---

When working with GitLab Duo, you might encounter issues.

Start by [running a health check](setup.md#run-a-health-check-for-gitlab-duo)
to determine if your instance meets the requirements to use GitLab Duo.

For more information on troubleshooting GitLab Duo, see:

- [Troubleshooting Code Suggestions](../project/repository/code_suggestions/troubleshooting.md).
- [GitLab Duo Chat troubleshooting](../gitlab_duo_chat/troubleshooting.md).
- [Troubleshooting GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/troubleshooting.md).

If the health check does not resolve your problem, review these troubleshooting steps.

## GitLab Duo features do not work on self-managed

In addition to [ensuring GitLab Duo features are turned on](turn_on_off.md),
you can also do the following:

1. As administrator, run a health check for GitLab Duo.

   {{< tabs >}}

   {{< tab title="In 17.5 and later" >}}

   In GitLab 17.5 and later, you can use the UI to run health checks and download a detailed report that helps identify and troubleshoot issues.

   {{< /tab >}}

   {{< tab title="In 17.4" >}}

   In GitLab 17.4, you can run the health check Rake task to generate a detailed report that helps identify and troubleshoot issues.

   ```shell
   sudo gitlab-rails 'cloud_connector:health_check(root,report.json)'
   ```

   {{< /tab >}}

   {{< tab title="In 17.3 and earlier" >}}

   In GitLab 17.3 and earlier, you can download and run the `health_check` script to generate a detailed report that helps identify and troubleshoot issues.

   1. Download the health check script:

      ```shell
      wget https://gitlab.com/gitlab-org/gitlab/-/snippets/3734617/raw/main/health_check.rb
      ```

   1. Run the script using Rails Runner:

      ```shell
      gitlab-rails runner [full_path/to/health_check.rb] --debug --username [username] --output-file [report.txt]
      ```

      ```shell
      Usage: gitlab-rails runner full_path/to/health_check.rb
             --debug                Enable debug mode
             --output-file FILE     Write a report to FILE
             --username USERNAME    Provide a username to test seat assignments
             --skip [CHECK]         Skip specific check (options: access_data, token, license, host, features, end_to_end)
      ```

   {{< /tab >}}

   {{< /tabs >}}

1. Verify that the GitLab instance can reach the [required GitLab.com endpoints](setup.md).
   You can use command-line tools such as `curl` to verify the connectivity.

   ```shell
   curl --verbose "https://cloud.gitlab.com"

   curl --verbose "https://customers.gitlab.com"
   ```

   If an HTTP/S proxy is configured for the GitLab instance, include the `proxy` parameter in the `curl` command.

   ```shell
   # https proxy for curl
   curl --verbose --proxy "http://USERNAME:PASSWORD@example.com:8080" "https://cloud.gitlab.com"
   curl --verbose --proxy "http://USERNAME:PASSWORD@example.com:8080" "https://customers.gitlab.com"
   ```

1. Optional. If you are using a [proxy server](setup.md#allow-outbound-connections-from-the-gitlab-instance) between the GitLab
   application and the public internet,
   [disable DNS rebinding protection](../../security/webhooks.md#enforce-dns-rebinding-attack-protection).

1. [Manually synchronize subscription data](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data).
   - Verify that the GitLab instance [synchronizes your subscription data with GitLab](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/).

## GitLab Duo features not available for users

In addition to [turning on GitLab Duo features](turn_on_off.md),
you can also do the following:

- If you have GitLab Duo Core, verify that you have:
  - A Premium or Ultimate subscription.
  - [Turned on IDE features](turn_on_off.md#turn-gitlab-duo-core-on-or-off).
- If you have GitLab Duo Pro or Enterprise:
  - Verify that [a subscription add-on has been purchased](../../subscriptions/subscription-add-ons.md#purchase-gitlab-duo).
  - Ensure that [seats are assigned to users](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
- For your IDE:
  - Verify that the [extension](../project/repository/code_suggestions/set_up.md#configure-editor-extension)
    or plugin is up-to-date.
  - Run health checks, and test the authentication.
