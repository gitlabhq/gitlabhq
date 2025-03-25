---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to use GitLab Pages to deploy a static website at no additional cost.
title: GitLab Pages
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Pages publishes static websites directly from a repository in GitLab.

<div class="row">
<div class="col-md-9">
<p style="margin-top: 18px;">
These websites:

- Deploy automatically with GitLab CI/CD pipelines.
- Support any static site generator (like Hugo, Jekyll, or Gatsby) or plain HTML, CSS, and JavaScript.
- Run on GitLab-provided infrastructure at no additional cost.
- Connect with custom domains and SSL/TLS certificates.
- Control access through built-in authentication.
- Scale reliably for personal, business, or project documentation sites.

</p>
</div>
<div class="col-md-3"><img src="img/ssgs_pages_v11_3.png" alt="Examples of SSGs supported by Pages" class="middle display-block"></div>
</div>

To publish a website with Pages, use any static site generator like Gatsby, Jekyll, Hugo, Middleman, Harp, Hexo, or Brunch.
Pages also supports websites written directly in plain HTML, CSS, and JavaScript.
Dynamic server-side processing (like `.php` and `.asp`) is not supported.
For more information, see [Static vs dynamic websites](https://about.gitlab.com/blog/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/).

## Getting started

To create a GitLab Pages website:

| Document                                                                             | Description                                                                                  |
|--------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| [Use the GitLab UI to create a simple `.gitlab-ci.yml`](getting_started/pages_ui.md) | Add a Pages site to an existing project. Use the UI to set up a simple `.gitlab-ci.yml`.     |
| [Create a `.gitlab-ci.yml` file from scratch](getting_started/pages_from_scratch.md) | Add a Pages site to an existing project. Learn how to create and configure your own CI file. |
| [Use a `.gitlab-ci.yml` template](getting_started/pages_ci_cd_template.md)           | Add a Pages site to an existing project. Use a pre-populated CI template file.               |
| [Fork a sample project](getting_started/pages_forked_sample_project.md)              | Create a new project with Pages already configured by forking a sample project.              |
| [Use a project template](getting_started/pages_new_project_template.md)              | Create a new project with Pages already configured by using a template.                      |

To update a GitLab Pages website:

| Document | Description |
|----------|-------------|
| [GitLab Pages domain names, URLs, and base URLs](getting_started_part_one.md) | Learn about GitLab Pages default domains. |
| [Explore GitLab Pages](introduction.md) | Requirements, technical aspects, specific GitLab CI/CD configuration options, Access Control, custom 404 pages, limitations, and FAQ. |
| [Custom domains and SSL/TLS Certificates](custom_domains_ssl_tls_certification/_index.md) | Custom domains and subdomains, DNS records, and SSL/TLS certificates. |
| [Let's Encrypt integration](custom_domains_ssl_tls_certification/lets_encrypt_integration.md) | Secure your Pages sites with Let's Encrypt certificates, which are automatically obtained and renewed by GitLab. |
| [Redirects](redirects.md) | Set up HTTP redirects to forward one page to another. |

For more information, see:

| Document | Description |
|----------|-------------|
| [Static vs dynamic websites](https://about.gitlab.com/blog/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/) | Static versus dynamic site overview. |
| [Modern static site generators](https://about.gitlab.com/blog/2016/06/10/ssg-overview-gitlab-pages-part-2/) | SSG overview. |
| [Build any SSG site with GitLab Pages](https://about.gitlab.com/blog/2016/06/17/ssg-overview-gitlab-pages-part-3-examples-ci/) | Use SSGs for GitLab Pages. |

## How it works

To use GitLab Pages, you must create a project in GitLab to upload your website's
files to. These projects can be either public, internal, or private.

GitLab always deploys your website from a specific folder called `public` in your
repository. When you create a new project in GitLab, a [repository](../repository/_index.md)
becomes available automatically.

To deploy your site, GitLab uses its built-in tool called [GitLab CI/CD](../../../ci/_index.md)
to build your site and publish it to the GitLab Pages server. The sequence of
scripts that GitLab CI/CD runs to accomplish this task is created from a file named
`.gitlab-ci.yml`, which you can [create and modify](getting_started/pages_from_scratch.md).
A user-defined `job` with `pages: true` property in the configuration file makes
GitLab aware that you're deploying a GitLab Pages website.

You can either use the GitLab [default domain for GitLab Pages websites](getting_started_part_one.md#gitlab-pages-default-domain-names),
`*.gitlab.io`, or your own domain (`example.com`). In that case, you
must be an administrator in your domain's registrar (or control panel) to set it up with Pages.

The following diagrams show the workflows you might follow to get started with Pages.

<img src="img/new_project_for_pages_v12_5.png" alt="New projects for GitLab Pages">

## Access to your Pages site

If you're using GitLab Pages default domain (`.gitlab.io`), your website is
automatically secure and available under HTTPS. If you're using your own custom
domain, you can optionally secure it with SSL/TLS certificates.

If you're using GitLab.com, your website is publicly available to the internet.
To restrict access to your website, enable [GitLab Pages Access Control](pages_access_control.md).

If you're using a GitLab Self-Managed instance, your websites are published on your
own server, according to the [Pages settings](../../../administration/pages/_index.md)
chosen by your sysadmin, who can make them public or internal.

## Pages examples

These GitLab Pages website examples can teach you advanced techniques to use
and adapt for your own needs:

- [Posting to your GitLab Pages blog from iOS](https://about.gitlab.com/blog/2016/08/19/posting-to-your-gitlab-pages-blog-from-ios/).
- [GitLab CI: Run jobs sequentially, in parallel, or build a custom pipeline](https://about.gitlab.com/blog/2020/12/10/basics-of-gitlab-ci-updated/).
- [GitLab CI: Deployment & environments](https://about.gitlab.com/blog/2021/02/05/ci-deployment-and-environments/).
- [Building a new GitLab docs site with Nanoc, GitLab CI, and GitLab Pages](https://about.gitlab.com/blog/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/).
- [Publish code coverage reports with GitLab Pages](https://about.gitlab.com/blog/2016/11/03/publish-code-coverage-report-with-gitlab-pages/).

## Administer GitLab Pages for GitLab Self-Managed instances

If you are running a GitLab Self-Managed instance,
[follow the administration steps](../../../administration/pages/_index.md) to configure Pages.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Watch a [video tutorial](https://www.youtube.com/watch?v=dD8c7WNcc6s) about how to get started with GitLab Pages administration.

### Configure GitLab Pages in a Helm Chart (Kubernetes) instance

To configure GitLab Pages on instances deployed with Helm chart (Kubernetes), use either:

- [The `gitlab-pages` subchart](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/).
- [An external GitLab Pages instance](https://docs.gitlab.com/charts/advanced/external-gitlab-pages/).

## Security for GitLab Pages

### Namespaces that contain `.`

If your username is `example`, your GitLab Pages website is located at `example.gitlab.io`.
GitLab allows usernames to contain a `.`, so a user named `bar.example` could create
a GitLab Pages website `bar.example.gitlab.io` that effectively is a subdomain of your
`example.gitlab.io` website. Be careful if you use JavaScript to set cookies for your website.
The safe way to manually set cookies with JavaScript is to not specify the `domain` at all:

```javascript
// Safe: This cookie is only visible to example.gitlab.io
document.cookie = "key=value";

// Unsafe: This cookie is visible to example.gitlab.io and its subdomains,
// regardless of the presence of the leading dot.
document.cookie = "key=value;domain=.example.gitlab.io";
document.cookie = "key=value;domain=example.gitlab.io";
```

This issue doesn't affect users with a custom domain, or users who don't set any
cookies manually with JavaScript.

### Shared cookies

By default, every project in a group shares the same domain, for example, `group.gitlab.io`. This means that cookies are also shared for all projects in a group.

To ensure each project uses different cookies, enable the Pages [unique domains](#unique-domains) feature for your project.

## Unique domains

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9347) in GitLab 15.9 [with a flag](../../../administration/feature_flags.md) named `pages_unique_domain`. Disabled by default.
- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/388151) in GitLab 15.11.
- [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122229) in GitLab 16.3.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163523) unique domain URLs to be shorter in GitLab 17.4.

{{< /history >}}

By default, every new project uses pages unique domain. This is to avoid projects on the same group
to share cookies.

The project maintainer can disable this feature on:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Pages**.
1. Clear the **Use unique domain** checkbox.
1. Select **Save changes**.

For example URLs, see [GitLab Pages default domain names](getting_started_part_one.md#gitlab-pages-default-domain-names).

## Primary domain

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481334) in GitLab 17.8.

{{< /history >}}

When you use GitLab Pages with custom domains, you can redirect all requests to GitLab Pages to a primary domain.
When the primary domain is selected, users receive `308 Permanent Redirect` status that redirects the browser to the
selected primary domain. Browsers might cache this redirect.

Prerequisites:

- You must have at least the Maintainer role for the project.
- A [custom domain](custom_domains_ssl_tls_certification/_index.md#set-up-a-custom-domain) must be set up.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Pages**.
1. From the **Primary domain** dropdown list, select the domain to redirect to.
1. Select **Save changes**.

## Expiring deployments

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162826) in GitLab 17.4.

{{< /history >}}

You can configure your Pages deployments to be automatically deleted after
a period of time has passed by specifying a duration at [`pages.expire_in`](../../../ci/yaml/_index.md#pagesexpire_in):

```yaml
create-pages:
  stage: deploy
  script:
    - ...
  pages:  # specifies that this is a Pages job and publishes the default public directory
    expire_in: 1 week
```

Expired deployments are stopped by a cron job that runs every 10 minutes.
Stopped deployments are subsequently deleted by another cron job that also
runs every 10 minutes. To recover it, follow the steps described in
[Recover a stopped deployment](#recover-a-stopped-deployment).

A stopped or deleted deployment is no longer available on the web.
Users see a `404 Not found` error page at its URL, until another deployment is created
with the same URL configuration.

The previous YAML example uses [user-defined job names](#user-defined-job-names).

### Recover a stopped deployment

Prerequisites:

- You must have at least the Maintainer role for the project.

To recover a stopped deployment that has not yet been deleted:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Pages**.
1. Near **Deployments** turn on the **Include stopped deployments** toggle.
   If your deployment has not been deleted yet, it should be included in the
   list.
1. Expand the deployment you want to recover and select **Restore**.

### Delete a Deployment

To delete a deployment:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Pages**.
1. Under **Deployments**, select any area on the deployment you wish to delete.
   The deployment details expand.
1. Select **Delete**.

When you select **Delete**, your deployment is stopped immediately.
Stopped deployments are deleted by a cron job running every 10 minutes.

To restore a stopped deployment that has not been deleted yet, see
[Recover a stopped deployment](#recover-a-stopped-deployment).

## User-defined job names

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/232505) in GitLab 17.5 with a flag `customizable_pages_job_name`, disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169095) in GitLab 17.6. Feature flag `customizable_pages_job_name` removed.

{{< /history >}}

To trigger a Pages deployment from any job, include the `pages` property in the
job definition. It can either be a Boolean set to `true` or a hash.

For example, using `true`:

```yaml
deploy-my-pages-site:
  stage: deploy
  script:
    - npm run build
  pages: true  # specifies that this is a Pages job and publishes the default public directory
```

For example, using a hash:

```yaml
deploy-pages-review-app:
  stage: deploy
  script:
    - npm run build
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: '_staging'
```

If the `pages` property of a job named `pages` is set to `false`, no
deployment is triggered:

```yaml
pages:
  pages: false
```

## Parallel deployments

To create multiple deployments for your project at the same time, for example to
create review apps, view the documentation on [Parallel Deployments](parallel_deployments.md).
