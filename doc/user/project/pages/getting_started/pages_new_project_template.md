---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Create a GitLab Pages website from a project template **(FREE)**

GitLab provides templates for the most popular Static Site Generators (SSGs).
You can create a new project from a template and run the CI/CD pipeline to generate a Pages website.

Use a template when you want to test GitLab Pages or start a new project that's already
configured to generate a Pages site.

1. From the top navigation, select the **+** button and select **New project**.
1. Select **Create from Template**.
1. Next to one of the templates starting with **Pages**, select **Use template**.

   ![Project templates for Pages](../img/pages_project_templates_v13_1.png)

1. Complete the form and select **Create project**.
1. From the left sidebar, navigate to your project's **CI/CD > Pipelines**
   and select **Run pipeline** to trigger GitLab CI/CD to build and deploy your
   site.

When the pipeline is finished, go to **Settings > Pages** to find the link to
your Pages website.
If this path is not visible, select **Deployments > Pages**.
[This location is part of an experiment](../index.md#menu-position-test).

For every change pushed to your repository, GitLab CI/CD runs a new pipeline
that immediately publishes your changes to the Pages site.

To view the HTML and other assets that were created for the site,
[download the job artifacts](../../../../ci/jobs/job_artifacts.md#download-job-artifacts).
