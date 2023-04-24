---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Jira DVCS connector **(FREE)**

Refer to the items in this section if you're having problems with your Jira DVCS connector.

## Jira cannot access GitLab server

If you complete the **Add New Account** form, authorize access, and you receive
this error, Jira and GitLab cannot connect. No other error messages
appear in any logs:

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

## Session token bug in Jira

When using GitLab 15.0 and later (including GitLab.com) with Jira Server, you might experience
a [session token bug in Jira](https://jira.atlassian.com/browse/JSWSERVER-21389). As a workaround,
ensure Jira Server is version 9.1.0 and later or 8.20.11 and later.

## SSL and TLS problems

Problems with SSL and TLS can cause this error message:

```plaintext
Error obtaining access token. Cannot access https://gitlab.example.com from Jira.
```

- The [Jira integration](../index.md) requires
  GitLab to connect to Jira. Any TLS issues that arise from a private certificate
  authority or self-signed certificate are resolved
  [on the GitLab server](https://docs.gitlab.com/omnibus/settings/ssl/index.html#install-custom-public-certificates),
  as GitLab is the TLS client.
- The Jira development panel requires Jira to connect to GitLab, which
  causes Jira to be the TLS client. If your GitLab server's certificate is not
  issued by a public certificate authority, add the appropriate certificate
  (such as your organization's root certificate) to the Java Truststore on Jira Server.

For help with Jira setup, see the Atlassian documentation and Atlassian Support:

- [Add a certificate](https://confluence.atlassian.com/kb/how-to-import-a-public-ssl-certificate-into-a-jvm-867025849.html)
  to the trust store.
  - The simplest approach is [`keytool`](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html).
  - Add additional roots to Java's default Truststore (`cacerts`) to allow Jira to
    also trust public certificate authorities.
  - If the integration stops working after upgrading Jira Java runtime, the
    `cacerts` Truststore may have been replaced during the upgrade.

- Troubleshoot connectivity [up to and including TLS handshaking](https://confluence.atlassian.com/kb/unable-to-connect-to-ssl-services-due-to-pkix-path-building-failed-error-779355358.html),
  using the `SSLPoke` Java class.
- Download the class from the Atlassian knowledge base to a directory on Jira Server, such as `/tmp`.
- Use the same Java runtime as Jira.
- Pass all networking-related parameters that Jira is called with, such as proxy
  settings or an alternative root Truststore (`-Djavax.net.ssl.trustStore`):

```shell
${JAVA_HOME}/bin/java -Djavax.net.ssl.trustStore=/var/atlassian/application-data/jira/cacerts -classpath /tmp SSLPoke gitlab.example.com 443
```

The message `Successfully connected` indicates a successful TLS handshake.

If there are problems, the Java TLS library generates errors that you can
look up for more detail.

## Scope error when connecting to Jira using DVCS

```plaintext
The requested scope is invalid, unknown, or malformed.
```

Potential resolutions:

1. Verify that the URL shown in the browser after being redirected from Jira in the
   [Jira DVCS connector setup](index.md#configure-jira-for-dvcs) includes `scope=api` in
   the query string.
1. If `scope=api` is missing from the URL, edit the
   [GitLab account configuration](index.md#configure-a-gitlab-application-for-dvcs). Review
   the **Scopes** field and ensure the `api` checkbox is selected.

## Jira error adding account and no repositories listed

After you complete the **Add New Account** form in Jira and authorize access, you might
encounter these issues:

- An `Error! Failed adding the account: [Error retrieving list of repositories]` error.
- An `Account is already integrated with JIRA` error when you select **Try Again**.
- An account is visible in the DVCS accounts view, but no repositories are listed.

To resolve this issue:

- If you're using GitLab Free, ensure you're using GitLab 13.4 or later.
- If you're using GitLab versions 11.10-12.7, upgrade to GitLab 12.8.10 or later
  to resolve [an identified issue](https://gitlab.com/gitlab-org/gitlab/-/issues/37012).

[Contact GitLab Support](https://about.gitlab.com/support/) if none of these reasons apply.

## `410 : Gone` error when connecting to Jira

When you connect to Jira and synchronize repositories, you may receive a `410 : Gone` error.

This issue occurs when you use the Jira DVCS connector and your integration is configured to use **GitHub Enterprise**.

For more information and possible fixes, see [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/340160).

## Synchronization issues

If Jira displays incorrect information, such as deleted branches, you may have to
resynchronize the information:

1. In Jira, select **Jira Administration > Applications > DVCS accounts**.
1. For the account (group or subgroup), select
   **Refresh repositories** from the **{ellipsis_h}** (ellipsis) menu.
1. For each project, next to the **Last activity** date:
   - To perform a *soft resync*, select the sync icon.
   - To complete a *full sync*, press `Shift` and select the sync icon.

For more information, see the
[Atlassian documentation](https://support.atlassian.com/jira-cloud-administration/docs/integrate-with-development-tools/).

## `Sync Failed` error when refreshing repository data

If you get a `Sync Failed` error in Jira when [refreshing repository data](index.md#refresh-data-imported-to-jira) for specific projects, check your Jira DVCS connector logs. Look for errors that occur when executing requests to API resources in GitLab. For example:

```plaintext
Failed to execute request [https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 GET https://gitlab.com/api/v4/projects/:id/merge_requests?page=1&per_page=100 returned a response status of 403 Forbidden] errors:
{"message":"403 Forbidden"}
```

If you find a `{"message":"403 Forbidden"}` error, it is possible that this specific project has some [GitLab features disabled](../../../user/project/settings/index.md#configure-project-visibility-features-and-permissions).
In the example above, the merge requests feature is disabled.

To resolve the issue, enable the relevant feature:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Use the toggles to enable the features as needed.

## Find webhook logs in a DVCS-linked project

To find webhook logs in a DVCS-linked project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Webhooks**.
1. Scroll down to **Project Hooks**.
1. Next to the log that points to your Jira instance, select **Edit**.
1. Scroll down to **Recent events**.

If you can't find webhook logs in your project, check your DVCS setup for problems.
