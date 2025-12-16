---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting GitLab Duo
---

When working with GitLab Duo, you might encounter issues.

Start by [running a health check](../../administration/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo)
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

1. Verify that the GitLab instance can reach the [required GitLab.com endpoints](../../administration/gitlab_duo/setup.md).
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

1. Optional. If you are using a [proxy server](../../administration/gitlab_duo/setup.md#allow-outbound-connections-from-the-gitlab-instance) between the GitLab
   application and the public internet,
   [disable DNS rebinding protection](../../security/webhooks.md#enforce-dns-rebinding-attack-protection).

1. [Manually synchronize subscription data](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data).
   - Verify that the GitLab instance [synchronizes your subscription data with GitLab](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/).

## Error: `Webview didn't initialize in 10000ms`

You might get this error when using GitLab Duo Chat in VS Code Remote SSH or WSL
sessions. The extension might also attempt to incorrectly connect to a `127.0.0.1` address.

This issue occurs when remote environments introduce latency that exceeds the
hardcoded 10-second timeout in GitLab VS Code Extension 6.8.0 and later.

To resolve this issue:

1. In VS Code, select **Code** > **Preferences** > **Settings**.
1. Select **Open Settings (JSON)** to edit your `settings.json` file.
   Alternatively, press <kbd>F1</kbd>, enter **Preferences: Open Settings (JSON)**,
   and select it.
1. Add this setting:

   ```json
   "gitlab.featureFlags.languageServerWebviews": false
   ```

1. Save and reload VS Code.

## Troubleshooting GitLab Duo on GitLab Dedicated

GitLab Duo Core should work out-of-the-box on GitLab 18.3 and later for Premium
and Ultimate customers.

Pre-production GitLab Dedicated instances do not support GitLab Duo Core by design.

### GitLab Duo settings not visible in Admin area

You might experience one or more of these issues:

- The **GitLab Duo** section doesn't appear in the Admin area.
- Configuration options are missing.
- API calls return `"addOnPurchases": []`.

These issues occur when your license is not properly synchronized with the instance.

To resolve this issue, create a support ticket to verify license synchronization.
Support can check synchronization status and request new license generation if needed.

### Error: `GitLab-workflow failed: the GitLab Language server failed to start in 10 seconds`

You might get this error when using GitLab Duo Chat in the Web IDE.
You might also see console errors about `Platform is missing!`

This issue occurs when network connectivity to `cloud.gitlab.com` and
`customers.gitlab.com` is blocked by network configuration.

To resolve this issue:

1. Verify outbound connections to `cloud.gitlab.com:443` and `customers.gitlab.com:443`.
1. Add [Cloudflare IP ranges](https://www.cloudflare.com/ips/) to your allowlist if needed.
1. Check for allowlist or firewall restrictions with
   [private link](../../administration/dedicated/configure_instance/network_security.md#aws-private-link-connectivity).
1. Follow [filtering outbound requests](../../security/webhooks.md#gitlab-duo-functionality-is-blocked)
   to troubleshoot connectivity issues.
1. Test connectivity from the instance.

### Error: `Unable to resolve resource`

You might get this error when the Web IDE fails to load.
Check browser logs for CORS errors: `failed to load because it violates the following Content Security policy`.

This issue occurs when CORS policies block required resources.

To resolve this issue:

1. Update to GitLab Workflow Extension version 6.35.1 or later.
1. Add `https://*.cdn.web-ide.gitlab-static.net` to your CORS policy.
1. To troubleshoot further, check HAR files for logs. For more information, see
   [create HAR files](../../user/application_security/api_fuzzing/create_har_files.md).

For more information, see [CORS issues](../../user/project/web_ide/_index.md#cors-issues).

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
