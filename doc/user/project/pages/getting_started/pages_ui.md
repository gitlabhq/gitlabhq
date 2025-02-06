---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create a GitLab Pages deployment for a static site
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

If you already have a GitLab project that contains your static site or framework,
you can generate a GitLab Pages website from it.

When you provide basic information in the UI, a `.gitlab-ci.yml` file is created
and a merge request opened. When you commit the merge request,
a pipeline deploys your Pages website.

## Prerequisites

- Your app must [output files to the `public` folder](../public_folder.md). If you create
  this folder during the build pipeline, you do not need to commit it to Git.

  WARNING:
  This step is important. Ensure your files are in a root-level `public` folder.

- You must have a project that either:
  - Generates static sites or a client-rendered single-page application (SPA),
    like [Eleventy](https://www.11ty.dev), [Astro](https://astro.build), or [Jekyll](https://jekyllrb.com).
  - Contains a framework configured for static output, such as [Next.js](https://nextjs.org),
    [Nuxt](https://nuxt.com), or [SvelteKit](https://kit.svelte.dev).
- GitLab Pages must be enabled for the project. (To enable, go to **Settings > General**,
  expand **Visibility, project features, permissions**, and turn on the **Pages** toggle.)

## Create the Pages deployment

To complete the setup and generate a GitLab Pages deployment:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Pages**.

   A **Get Started with Pages** form appears. If this form is not available,
   see [Troubleshooting](#if-the-get-started-with-pages-form-is-not-available).
1. For **Step 1**, enter an image name and verify that your files are in a `public` folder.
1. Select **Next**.
1. For **Step 2**, enter your installation steps. If your framework's build process does not
   need one of the provided build commands, you can either:
   - Skip the step by selecting **Next**.
   - Enter `:` (the bash "do nothing" command) if you still want to incorporate that
     step's boilerplate into your `.gitlab-ci.yml` file.
1. Select **Next**.
1. For **Step 3**, enter scripts that indicate how to build your application.
1. Select **Next**.
1. Optional. Edit the generated `.gitlab-ci.yml` file as needed.
1. For **Step 4**, add a commit message and select **Commit**. This commit triggers your first
   GitLab Pages deployment.

To view the running pipeline, go to **Build > Pipelines**.

To view the artifacts that were created during the deployment, view the job,
and on the right side, select **Download artifacts**.

## Troubleshooting

### If the `Get Started with Pages` form is not available

The `Get Started with Pages` form is not available if you:

- Deployed a GitLab Pages site before.
- Committed `.gitlab-ci.yml` through the forms at least one time.

To fix this issue:

- If the message **Waiting for the Pages Pipeline to complete** appears, select
  **Start over** to start the form again.
- If your project has previously deployed GitLab Pages successfully,
  [manually update](pages_from_scratch.md) your `.gitlab-ci.yml` file.
