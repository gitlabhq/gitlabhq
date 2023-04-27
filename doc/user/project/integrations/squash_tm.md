---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Squash TM **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/337855) in GitLab 15.10.

When [Squash TM](https://www.squashtest.com/squash-gitlab-integration?lang=en) (Test Management)
integration is enabled and configured in GitLab, issues (typically user stories) created in GitLab
are synchronized as requirements in Squash TM and test progress is reported in GitLab issues.

## Configure Squash TM

1. Optional. Ask your system administrator to [configure a token in the properties file](https://tm-en.doc.squashtest.com/latest/redirect/gitlab-integration-token.html).
1. Follow the [Squash TM documentation](https://tm-en.doc.squashtest.com/latest/redirect/gitlab-integration-configuration.html) to:
    1. Create a GitLab server.
    1. Enable the `Xsquash4GitLab` plugin
    1. Configure a synchronization.
    1. From the **Real-time synchronization** panel, copy the following fields to use later in GitLab:

       - **Webhook URL**.
       - **Secret token** if your Squash TM system administrator configured one at step 1.

## Configure GitLab

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Squash TM**.
1. Ensure that the **Active** toggle is enabled.
1. In the **Trigger** section, indicate which type of issue is concerned by the real-time synchronization.
1. Complete the fields:

   - Enter the **Squash TM webhook URL**,
   - Enter the **secret token** if your Squash TM system administrator configured it earlier.
