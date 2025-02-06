---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create a GitLab Pages website from a CI/CD template
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab provides `.gitlab-ci.yml` templates for the most popular Static Site Generators (SSGs).
You can create your own `.gitlab-ci.yml` file from one of these templates, and run
the CI/CD pipeline to generate a Pages website.

Use a `.gitlab-ci.yml` template when you have an existing project that you want to add a Pages site to.

Your GitLab repository should contain files specific to an SSG, or plain HTML. After you complete
these steps, you may have to do additional configuration for the Pages site to generate properly.

1. On the left sidebar, select **Search or go to** and find your project.
1. From the **Add** (**{plus}**) dropdown list, select **New file**.
1. From the **Select a template type** dropdown list, select `.gitlab-ci.yml`.
1. From the **Apply a template** dropdown list, in the **Pages** section, select the name of your SSG.
1. In the **Commit message** box, type the commit message.
1. Select **Commit changes**.

If everything is configured correctly, the site can take approximately 30 minutes to deploy.

To view the pipeline, go to **Build > Pipelines**.

When the pipeline is finished, go to **Deploy > Pages** to find the link to
your Pages website.

For every change pushed to your repository, GitLab CI/CD runs a new pipeline
that immediately publishes your changes to the Pages site.

To view the HTML and other assets that were created for the site,
[download the job artifacts](../../../../ci/jobs/job_artifacts.md#download-job-artifacts).
