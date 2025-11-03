---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create a GitLab Pages website from a project template
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab provides templates for the most popular Static Site Generators (SSGs).
You can create a new project from a template and run the CI/CD pipeline to generate a Pages website.

Use a template when you want to test GitLab Pages or start a new project that's already
configured to generate a Pages site.

1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Create from Template**.
1. Next to one of the templates starting with **Pages**, select **Use template**.
1. Complete the form and select **Create project**.
1. On the left sidebar, select **Build** > **Pipelines**
   and select **New pipeline** to trigger GitLab CI/CD to build and deploy your
   site.

When the pipeline is finished, go to **Deploy** > **Pages** to find the link to
your Pages website.

For every change pushed to your repository, GitLab CI/CD runs a new pipeline
that immediately publishes your changes to the Pages site.

To view the HTML and other assets that were created for the site,
[download the job artifacts](../../../../ci/jobs/job_artifacts.md#download-job-artifacts).

## Project templates

{{< history >}}

- [Removed](https://gitlab.com/groups/gitlab-org/-/epics/13847) the following templates from
  project templates in GitLab 18.0:
  [`Bridgetown`](https://gitlab.com/pages/bridgetown), [`Gatsby`](https://gitlab.com/pages/gatsby),
  [`Hexo`](https://gitlab.com/pages/hexo), [`Middleman`](https://gitlab.com/pages/middleman),
  `Netlify/GitBook`, [`Netlify/Hexo`](https://gitlab.com/pages/nfhexo),
  [`Netlify/Hugo`](https://gitlab.com/pages/nfhugo), [`Netlify/Jekyll`](https://gitlab.com/pages/nfjekyll),
  [`Netlify/Plain HTML`](https://gitlab.com/pages/nfplain-html), and [`Pelican`](https://gitlab.com/pages/pelican).

{{< /history >}}

GitLab maintains template projects for these frameworks:

| Realm          | Framework                                           | Available project templates |
|----------------|-----------------------------------------------------|-----------------------------|
| **Go**         | [`hugo`](https://gitlab.com/pages/hugo)             | Pages/Hugo                  |
| **Markdown**   | [`astro`](https://gitlab.com/pages/astro)           | Pages/Astro                 |
| **Markdown**   | [`docusaurus`](https://gitlab.com/pages/docusaurus) | Pages/Docusaurus            |
| **Plain HTML** | [`plain-html`](https://gitlab.com/pages/plain-html) | Pages/Plain HTML            |
| **React**      | [`next.js`](https://gitlab.com/pages/nextjs)        | Pages/Next.js               |
| **Ruby**       | [`jekyll`](https://gitlab.com/pages/jekyll)         | Pages/Jekyll                |
| **Vue.js**     | [`nuxt`](https://gitlab.com/pages/nuxt)             | Pages/Nuxt                  |
