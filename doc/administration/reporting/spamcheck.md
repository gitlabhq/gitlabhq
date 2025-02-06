---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Spamcheck anti-spam service
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

WARNING:
Spamcheck is available to all tiers, but only on instances using GitLab Enterprise Edition (EE). For [licensing reasons](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6259#note_726605397), it is not included in the GitLab Community Edition (CE) package. You can [migrate from CE to EE](../../update/package/convert_to_ee.md).

[Spamcheck](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck) is an anti-spam engine
developed by GitLab originally to combat rising amount of spam in GitLab.com,
and later made public to be used in GitLab Self-Managed instances.

## Enable Spamcheck

Spamcheck is only available for package-based installations:

1. Edit `/etc/gitlab/gitlab.rb` and enable Spamcheck:

   ```ruby
   spamcheck['enable'] = true
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Verify that the new services `spamcheck` and `spam-classifier` are
   up and running:

   ```shell
   sudo gitlab-ctl status
   ```

## Configure GitLab to use Spamcheck

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Reporting**.
1. Expand **Spam and Anti-bot Protection**.
1. Update the Spam Check settings:
   1. Check the "Enable Spam Check via external API endpoint" checkbox.
   1. For **URL of the external Spam Check endpoint** use `grpc://localhost:8001`.
   1. Leave **Spam Check API key** blank.
1. Select **Save changes**.

NOTE:
In single-node instances, Spamcheck runs over `localhost`, and hence is running
in an unauthenticated mode. If on multi-node instances where GitLab runs on one
server and Spamcheck runs on another server listening over a public endpoint, it
is recommended to enforce some sort of authentication using a reverse proxy in
front of the Spamcheck service that can be used along with an API key. One
example would be to use `JWT` authentication for this and specifying a bearer
token as the API key.
[Native authentication for Spamcheck is in the works](https://gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/spam/spamcheck/-/issues/171).

## Running Spamcheck over TLS

Spamcheck service on its own cannot communicate directly over TLS with GitLab.
However, Spamcheck can be deployed behind a reverse proxy which performs TLS
termination. In such a scenario, GitLab can be made to communicate with
Spamcheck over TLS by specifying `tls://` scheme for the external Spamcheck URL
instead of `grpc://` in the **Admin** area settings.
