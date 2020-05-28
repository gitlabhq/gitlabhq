---
description: 'Learn how to use GitLab Pages to deploy a static website at no additional cost.'
stage: Release
group: Release Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Pages

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80) in GitLab Enterprise Edition 8.3.
> - Custom CNAMEs with TLS support were [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173) in GitLab Enterprise Edition 8.5.
> - [Ported](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/14605) to GitLab Community Edition in GitLab 8.17.
> - Support for subgroup project's websites was [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30548) in GitLab 11.8.
> - Bundled project templates were [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/47857) in GitLab 11.8.

With GitLab Pages, you can publish static websites
directly from a repository in GitLab.

- Use for any personal or business website.
- Use any Static Site Generator (SSG) or plain HTML.
- Create websites for your projects, groups, or user account.
- Host your site on your own GitLab instance or on GitLab.com for free.
- Connect your custom domains and TLS certificates.
- Attribute any license to your content.

<div class="row">
<div class="col-md-9">
<p style="margin-top: 18px;">
To publish a website with Pages, you can use any SSG,
like Gatsby, Jekyll, Hugo, Middleman, Harp, Hexo, and Brunch, just to name a few. You can also
publish any website written directly in plain HTML, CSS, and JavaScript.</p>
<p>Pages does <strong>not</strong> support dynamic server-side processing, for instance, as <code>.php</code> and <code>.asp</code> requires. Learn more about
<a href="https://about.gitlab.com/blog/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/">static websites vs dynamic websites</a>.</p>
<p>Learn more about GitLab Pages:</p>
</div>
<div class="col-md-3"><img src="img/ssgs_pages.png" alt="Examples of SSGs supported by Pages" class="image-noshadow middle display-block"></div>
</div>

| Document | Description |
| --- | --- |
| [GitLab Pages domain names, URLs, and baseurls](getting_started_part_one.md) | How GitLab Pages default domains work. |
| [GitLab CI/CD for GitLab Pages](getting_started_part_four.md) | Create your own site by using `.gitlab-ci.yml`. |
| [Exploring GitLab Pages](introduction.md) | Requirements, technical aspects, specific GitLab CI/CD configuration options, Access Control, custom 404 pages, limitations, FAQ. |
|---+---|
| [Custom domains and SSL/TLS Certificates](custom_domains_ssl_tls_certification/index.md) | Add custom domains and subdomains to your website, configure DNS records and SSL/TLS certificates. |
| [Let's Encrypt integration](custom_domains_ssl_tls_certification/lets_encrypt_integration.md) | Secure your Pages sites with Let's Encrypt certificates, which are automatically obtained and renewed by GitLab. |
| [CloudFlare certificates](https://about.gitlab.com/blog/2017/02/07/setting-up-gitlab-pages-with-cloudflare-certificates/) | Secure your Pages site with CloudFlare certificates. |
|---+---|
| [Static vs dynamic websites](https://about.gitlab.com/blog/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/) | Static versus dynamic site overview. |
| [Modern static site generators](https://about.gitlab.com/blog/2016/06/10/ssg-overview-gitlab-pages-part-2/) | SSG overview. |
| [Build any SSG site with GitLab Pages](https://about.gitlab.com/blog/2016/06/17/ssg-overview-gitlab-pages-part-3-examples-ci/) | Use SSGs for GitLab Pages. |

## How it works

To use GitLab Pages, you must create a project in GitLab to upload your website's
files to. These projects can be either public, internal, or private.

GitLab always deploys your website from a very specific folder called `public` in your
repository. When you create a new project in GitLab, a [repository](../repository/index.md)
becomes available automatically.

To deploy your site, GitLab uses its built-in tool called [GitLab CI/CD](../../../ci/README.md)
to build your site and publish it to the GitLab Pages server. The sequence of
scripts that GitLab CI/CD runs to accomplish this task is created from a file named
`.gitlab-ci.yml`, which you can [create and modify](getting_started_part_four.md) at will. A specific `job` called `pages` in the configuration file will make GitLab aware that you are deploying a GitLab Pages website.

You can either use GitLab's [default domain for GitLab Pages websites](getting_started_part_one.md#gitlab-pages-default-domain-names),
`*.gitlab.io`, or your own domain (`example.com`). In that case, you'll
need admin access to your domain's registrar (or control panel) to set it up with Pages.

## Getting started

To get started with GitLab Pages, you can:

- [Use a bundled website template that's ready to go](getting_started/pages_bundled_template.md).
- [Copy an existing sample](getting_started/fork_sample_project.md).
- [Create a website from scratch or deploy an existing one](getting_started/new_or_existing_website.md).

<img src="img/new_project_for_pages_v12_5.png" alt="New projects for GitLab Pages" class="image-noshadow">

Optional features:

- Use a [custom domain or subdomain](custom_domains_ssl_tls_certification/index.md#set-up-pages-with-a-custom-domain).
- Add an [SSL/TLS certificate to secure your site under the HTTPS protocol](custom_domains_ssl_tls_certification/index.md#adding-an-ssltls-certificate-to-pages).

If you're using GitLab Pages default domain (`.gitlab.io`),
your website will be automatically secure and available under
HTTPS. If you're using your own custom domain, you can
optionally secure it with SSL/TLS certificates.

## Access to your Pages site

If you're using GitLab.com, your website will be publicly available to the internet.

To restrict access to your website, enable [GitLab Pages Access Control](pages_access_control.md).

If you're using a self-managed instance (Core, Starter, Premium, or Ultimate),
your websites will be published on your own server, according to the
[Pages admin settings](../../../administration/pages/index.md) chosen by your sysadmin,
who can make them public or internal.

## Pages examples

There are some great examples of GitLab Pages websites built for
specific reasons. These examples can teach you advanced techniques
to use and adapt to your own needs:

- [Posting to your GitLab Pages blog from iOS](https://about.gitlab.com/blog/2016/08/19/posting-to-your-gitlab-pages-blog-from-ios/).
- [GitLab CI: Run jobs sequentially, in parallel, or build a custom pipeline](https://about.gitlab.com/blog/2016/07/29/the-basics-of-gitlab-ci/).
- [GitLab CI: Deployment & environments](https://about.gitlab.com/blog/2016/08/26/ci-deployment-and-environments/).
- [Building a new GitLab docs site with Nanoc, GitLab CI, and GitLab Pages](https://about.gitlab.com/blog/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/).
- [Publish code coverage reports with GitLab Pages](https://about.gitlab.com/blog/2016/11/03/publish-code-coverage-report-with-gitlab-pages/).

## Administer GitLab Pages for self-managed instances

Enable and configure GitLab Pages on your own instance (GitLab Community Edition and Enterprise Editions) with
the [admin guide](../../../administration/pages/index.md).

**<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Watch a [video tutorial](https://www.youtube.com/watch?v=dD8c7WNcc6s) for getting started with GitLab Pages admin!**
