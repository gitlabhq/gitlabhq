---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Akismet **(FREE)**

GitLab leverages [Akismet](https://akismet.com/) to protect against spam.
GitLab uses Akismet to prevent the creation of spam issues on public projects. Issues
created through the web UI or the API can be submitted to Akismet for review.

Detected spam is rejected, and an entry is added in the **Spam Log** section of the
Admin page.

Privacy note: GitLab submits the user's IP and user agent to Akismet.

NOTE:
In GitLab 8.11 and later, all issues are submitted to Akismet.
In earlier GitLab versions, this only applied to API and non-project members.

## Configuration

To use Akismet:

1. Go to the [Akismet sign-in page](https://akismet.com/account/).
1. Sign in or create a new account.
1. Click **Show** to reveal the API key, and copy the API key's value.
1. Sign in to GitLab as an administrator.
1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Reporting** (`/admin/application_settings/reporting`).
1. Select the **Enable Akismet** checkbox.
1. Fill in the API key from step 3.
1. Save the configuration.

![Screenshot of Akismet settings](img/akismet_settings.png)

## Training

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
