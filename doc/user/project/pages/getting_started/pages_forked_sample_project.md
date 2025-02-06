---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create a GitLab Pages website from a forked sample project
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab provides [sample projects for the most popular Static Site Generators (SSG)](https://gitlab.com/pages).
You can fork one of the sample projects and run the CI/CD pipeline to generate a Pages website.

Fork a sample project when you want to test GitLab Pages or start a new project that's already
configured to generate a Pages site.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Watch a [video tutorial](https://www.youtube.com/watch?v=TWqh9MtT4Bg) of how this works.

To fork a sample project and create a Pages website:

1. View the sample projects by navigating to the [GitLab Pages examples](https://gitlab.com/pages) group.
1. Select the name of the project you want to [fork](../../repository/forking_workflow.md#create-a-fork).
1. In the upper-right corner, select **Fork**, then choose a namespace to fork to.
1. For your project, on the left sidebar, select **Build > Pipelines** and then **New pipeline**.
   GitLab CI/CD builds and deploys your site.

The site can take approximately 30 minutes to deploy.
When the pipeline is finished, go to **Deploy > Pages** to find the link to
your Pages website.

For every change pushed to your repository, GitLab CI/CD runs a new pipeline
that immediately publishes your changes to the Pages site.

## Remove the fork relationship

If you want to contribute to the project you forked from,
you can keep the forked relationship. Otherwise:

1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced settings**.
1. Select **Remove fork relationship**.

## Change the URL

You can change the URL to match your namespace.
If your Pages site is hosted on GitLab.com,
you can rename it to `<namespace>.gitlab.io`, where `<namespace>` is your GitLab namespace
(the one you chose when you forked the project).

1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. In **Change path**, update the path to `<namespace>.gitlab.io`.

   For example, if your project's URL is `gitlab.com/gitlab-tests/jekyll`, your namespace is
   `gitlab-tests`.

   If you set the repository path to `gitlab-tests.gitlab.io`,
   the resulting URL for your Pages website is `https://gitlab-tests.gitlab.io`.

   ![Change repository's path](../img/change_path_v12_10.png)

1. Open your SSG configuration file and change the [base URL](../getting_started_part_one.md#urls-and-base-urls)
   from `"project-name"` to `""`. The project name setting varies by SSG and may not be in the configuration file.

## Related topics

- [Download the job artifacts](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)
