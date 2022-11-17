---
stage: Create
group: Incubation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial: Use the GitLab UI to deploy your static site **(FREE)**

This tutorial assumes you have a project that either:

- Generates static sites or a client-rendered single-page application (SPA),
  such as [Eleventy](https://www.11ty.dev), [Astro](https://astro.build), or [Jekyll](https://jekyllrb.com).
- Contains a framework configured for static output, such as [Next.js](https://nextjs.org),
  [Nuxt.js](https://nuxtjs.org), or [SvelteKit](https://kit.svelte.dev).

## Update your app to output files to the `public` folder

GitLab Pages requires all files intended to be part of the published website to
be in a root-level folder called `public`. If you create this folder during the build
pipeline, committing it to Git is not required.

For detailed instructions, read [Configure the public files folder](../public_folder.md).

## Set up the `.gitlab-ci.yml` file

GitLab helps you write the `.gitlab-ci.yml` needed to create your first GitLab Pages
deployment pipeline. Rather than building the file from scratch, it asks you to
provide the build commands, and creates the necessary boilerplate for you.

To build your YAML file from the GitLab UI:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Pages** to display the friendly
   interface **Get Started With Pages**.
1. If your framework's build process does not need one of the provided build
   commands, you can either:
   - Skip the step by selecting **Next**.
   - Enter `:` (the bash "do nothing" command) if you still want to incorporate that
     step's boilerplate into your `.gitlab-ci.yml` file.
1. Optional. Edit and adjust the generated `.gitlab-ci.yml` file as needed.
1. Commit your `.gitlab-ci.yml` to your repository. This commit triggers your first
   GitLab Pages deployment.

To view the HTMl and other assets that were created for the site,
go to **CI/CD > Pipelines**, view the job, and on the right side,
select **Download artifacts**.

## Troubleshooting

### If you can't see the "Get Started with Pages" interface

GitLab doesn't show this interface if you have either:

- Deployed a GitLab Pages site before.
- Committed a `.gitlab-ci.yml` through this interface at least once.

To fix this problem:

- If you see the message **Waiting for the Pages Pipeline to complete**, select
  **Start over** to start the wizard again.
- If your project has previously deployed GitLab Pages successfully,
  [manually update](pages_from_scratch.md) your `.gitlab-ci.yml`.
