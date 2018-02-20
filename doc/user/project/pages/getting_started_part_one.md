---
last_updated: 2018-02-16
author: Marcia Ramos
author_gitlab: marcia
level: beginner
article_type: user guide
date: 2017-02-22
---

# Static sites and GitLab Pages domains

This document is the beginning of a comprehensive guide, made for those who want to
publish a website with GitLab Pages but aren't familiar with
the entire process involved.

This [first document](#what-you-need-to-know-before-getting-started) of this series will present you to the concepts of
static sites, and go over how the default Pages domains work.

The [second document](getting_started_part_two.md) covers how to get started with GitLab Pages: deploy
a website from a forked project or create a new one from scratch.

The [third document](getting_started_part_three.md) will show you how to set up a custom domain or subdomain
to your site already deployed.

The [fourth document](getting_started_part_four.md) will show you how to create and tweak GitLab CI for
GitLab Pages.

To **enable** GitLab Pages for GitLab CE (Community Edition)
and GitLab EE (Enterprise Edition), please read the
[admin documentation](https://docs.gitlab.com/ce/administration/pages/index.html),
and/or watch this [video tutorial](https://youtu.be/dD8c7WNcc6s).

>**Note:**
For this guide, we assume you already have GitLab Pages
server up and running for your GitLab instance.

## What you need to know before getting started

Before we begin, let's understand a few concepts first.

## Static sites

GitLab Pages only supports static websites, meaning,
your output files must be HTML, CSS, and JavaScript only.

To create your static site, you can either hardcode in HTML,
CSS, and JS, or use a [Static Site Generator (SSG)](https://www.staticgen.com/)
to simplify your code and build the static site for you,
which is highly recommendable and much faster than hardcoding.

### Further reading

- Read through this technical overview on [Static versus Dynamic Websites](https://about.gitlab.com/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/)
- Understand [how modern Static Site Generators work](https://about.gitlab.com/2016/06/10/ssg-overview-gitlab-pages-part-2/) and what you can add to your static site
- You can use [any SSG with GitLab Pages](https://about.gitlab.com/2016/06/17/ssg-overview-gitlab-pages-part-3-examples-ci/)
- Fork an [example project](https://gitlab.com/pages) to build your website based upon

## GitLab Pages domain

If you set up a GitLab Pages project on GitLab.com,
it will automatically be accessible under a
[subdomain of `namespace.gitlab.io`](introduction.md#gitlab-pages-on-gitlab-com).
The `namespace` is defined by your username on GitLab.com,
or the group name you created this project under.

>**Note:**
If you use your own GitLab instance to deploy your
site with GitLab Pages, check with your sysadmin what's your
Pages wildcard domain. This guide is valid for any GitLab instance,
you just need to replace Pages wildcard domain on GitLab.com
(`*.gitlab.io`) with your own.

Learn more about [namespaces](../../group/index.md#namespaces).

### Practical examples

#### Project Websites

- You created a project called `blog` under your username `john`,
therefore your project URL is `https://gitlab.com/john/blog/`.
Once you enable GitLab Pages for this project, and build your site,
it will be available under `https://john.gitlab.io/blog/`.
- You created a group for all your websites called `websites`,
and a project within this group is called `blog`. Your project
URL is `https://gitlab.com/websites/blog/`. Once you enable
GitLab Pages for this project, the site will live under
`https://websites.gitlab.io/blog/`.

#### User and Group Websites

- Under your username, `john`, you created a project called
`john.gitlab.io`. Your project URL will be `https://gitlab.com/john/john.gitlab.io`.
Once you enable GitLab Pages for your project, your website
will be published under `https://john.gitlab.io`.
- Under your group `websites`, you created a project called
`websites.gitlab.io`. your project's URL will be `https://gitlab.com/websites/websites.gitlab.io`.
Once you enable GitLab Pages for your project,
your website will be published under `https://websites.gitlab.io`.

>**Note:**
GitLab Pages [does **not** support subgroups](../../group/subgroups/index.md#limitations).
You can only create the highest level group website.

**General example:**

- On GitLab.com, a project site will always be available under
`https://namespace.gitlab.io/project-name`
- On GitLab.com, a user or group website will be available under
`https://namespace.gitlab.io/`
- On your GitLab instance, replace `gitlab.io` above with your
Pages server domain. Ask your sysadmin for this information.

_Read on about [Projects for GitLab Pages and URL structure](getting_started_part_two.md)._
