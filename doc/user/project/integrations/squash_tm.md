---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Squash TM
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/337855) in GitLab 15.10.

When [Squash TM](https://www.squashtest.com/en/squash-gitlab-platform) (Test Management)
integration is enabled and configured in GitLab, issues (typically user stories) created in GitLab
are synchronized as requirements in Squash TM and test progress is reported in GitLab issues.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of optimizing your DevSecOps workflow with the Squash TM and GitLab integration,
see [Leverage Requirements and Test management in your SDLC](https://www.youtube.com/watch?v=XAiNUmBiqm4).
<!-- Video published on 2024-05-15 -->

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

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Squash TM**.
1. Ensure that the **Active** toggle is enabled.
1. In the **Trigger** section, indicate which type of issue is concerned by the real-time synchronization.
1. Complete the fields:

   - Enter the **Squash TM webhook URL**,
   - Enter the **secret token** if your Squash TM system administrator configured it earlier.
