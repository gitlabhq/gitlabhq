---
stage: Govern
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Akismet

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

GitLab uses [Akismet](https://akismet.com/) to prevent the creation of
spam issues on public projects. Issues created through the web UI or the API can be submitted to
Akismet for review, and instance administrators can
[mark snippets as spam](../user/snippets.md#mark-snippet-as-spam).

Detected spam is rejected, and an entry is added in the **Spam Log** section of the
Admin Area.

Privacy note: GitLab submits the user's IP and user agent to Akismet.

NOTE:
GitLab submits all issues to Akismet.

Akismet configuration is available to users on self-managed GitLab. Akismet is already enabled on
GitLab SaaS (GitLab.com), where its configuration and management are handled by GitLab Inc.

## Configure Akismet

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

To use Akismet:

1. Go to the [Akismet sign-in page](https://akismet.com/account/).
1. Sign in or create a new account.
1. Select **Show** to reveal the API key, and copy the API key's value.
1. Sign in to GitLab as an administrator.
1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Reporting**.
1. Expand **Spam and Anti-bot Protection**.
1. Select the **Enable Akismet** checkbox.
1. Fill in the API key from step 3.
1. Save the configuration.

![Screenshot of Akismet settings](img/akismet_settings.png)

## Train the Akismet filter

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

To better differentiate between spam and ham, you can train the Akismet
filter whenever there is a false positive or false negative.

When an entry is recognized as spam, it is rejected and added to the Spam Logs.
From here you can review if entries are really spam. If one of them is not really
spam, you can use the **Submit as ham** button to tell Akismet that it falsely
recognized an entry as spam.

![Screenshot of Spam Logs](img/spam_log.png)

If an entry that is actually spam was not recognized as such, you can also submit
this information to Akismet. The **Submit as spam** button is only displayed
to administrator users.

![Screenshot of Issue](img/submit_issue.png)

Training Akismet helps it to recognize spam more accurately in the future.
