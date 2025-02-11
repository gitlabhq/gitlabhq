---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages default domain names and URLs
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

On this document, learn how to name your project for GitLab Pages
according to your intended website's URL.

## GitLab Pages default domain names

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163523) unique domain URLs to be shorter in GitLab 17.4.

If you use your own GitLab instance to deploy your site with GitLab Pages, verify your Pages
wildcard domain with your sysadmin. This guide is valid for any GitLab instance, provided that you
replace the Pages wildcard domain on GitLab.com (`*.gitlab.io`) with your own.

If you set up a GitLab Pages project on GitLab,
it's automatically accessible under a
subdomain of `namespace.example.io`.
The [`namespace`](../../namespace/_index.md)
is defined by your username on GitLab.com,
or the group name you created this project under.
For GitLab Self-Managed, replace `example.io`
with your instance's Pages domain. For GitLab.com,
Pages domains are `*.gitlab.io`.

| Type of GitLab Pages | Example path of a project in GitLab | Website URL |
| -------------------- | ------------ | ----------- |
| User pages  | `username/username.example.io`  | `http(s)://username.example.io`  |
| Group pages | `acmecorp/acmecorp.example.io` | `http(s)://acmecorp.example.io` |
| Project pages owned by a user  | `username/my-website` | `http(s)://username.example.io/my-website` |
| Project pages owned by a group | `acmecorp/webshop` | `http(s)://acmecorp.example.io/webshop`|
| Project pages owned by a subgroup | `acmecorp/documentation/product-manual` | `http(s)://acmecorp.example.io/documentation/product-manual`|

When the **Use unique domain** setting is enabled, Pages builds a unique domain name from
the flattened project name and a six-character unique ID. Users receive a `308 Permanent Redirect` status
redirecting the browser to these unique domain URLs. Browsers might cache this redirect:

| Type of GitLab Pages              | Example path of a project in GitLab     | Website URL |
| --------------------------------- | --------------------------------------- | ----------- |
| User pages                        | `username/username.example.io`          | `http(s)://username-example-io-123456.example.io` |
| Group pages                       | `acmecorp/acmecorp.example.io`          | `http(s)://acmecorp-example-io-123456.example.io` |
| Project pages owned by a user     | `username/my-website`                   | `https://my-website-123456.gitlab.io/` |
| Project pages owned by a group    | `acmecorp/webshop`                      | `http(s)://webshop-123456.example.io/` |
| Project pages owned by a subgroup | `acmecorp/documentation/product-manual` | `http(s)://product-manual-123456.example.io/` |

`123456` in the example URLs is a six-character unique ID.
For example, if the unique ID is `f85695`, the last example is
`http(s)://product-manual-f85695.example.io/`.

WARNING:
There are some known [limitations](introduction.md#subdomains-of-subdomains)
regarding namespaces served under the general domain name and HTTPS.
Make sure to read that section.

To understand Pages domains clearly, read the examples below.

NOTE:
The following examples imply you disabled the **Use unique domain** setting. If you did not, refer to the previous table, replacing `example.io` by `gitlab.io`.

### Project website examples

- You created a project called `blog` under your username `john`,
  therefore your project URL is `https://gitlab.com/john/blog/`.
  After you enabled GitLab Pages for this project, and build your site,
  you can access it at `https://john.gitlab.io/blog/`.
- You created a group for all your websites called `websites`,
  and a project in this group is called `blog`. Your project
  URL is `https://gitlab.com/websites/blog/`. After you enabled
  GitLab Pages for this project, the site is available at
  `https://websites.gitlab.io/blog/`.
- You created a group for your engineering department called `engineering`,
  a subgroup for all your documentation websites called `docs`,
  and a project in this subgroup is called `workflows`. Your project
  URL is `https://gitlab.com/engineering/docs/workflows/`. After you enabled
  GitLab Pages for this project, the site is available at
  `https://engineering.gitlab.io/docs/workflows`.

### User and Group website examples

- Under your username, `john`, you created a project called
  `john.gitlab.io`. Your project URL is `https://gitlab.com/john/john.gitlab.io`.
  After you enabled GitLab Pages for your project, your website
  is published under `https://john.gitlab.io`.
- Under your group `websites`, you created a project called
  `websites.gitlab.io`. Your project's URL is `https://gitlab.com/websites/websites.gitlab.io`.
  After you enabled GitLab Pages for your project,
  your website is published under `https://websites.gitlab.io`.

**General example:**

- On GitLab.com, a project site is always available under
  `https://namespace.gitlab.io/project-slug`
- On GitLab.com, a user or group website is available under
  `https://namespace.gitlab.io/`
- On your GitLab instance, replace `gitlab.io` above with your
  Pages server domain. Ask your sysadmin for this information.

## URLs and base URLs

NOTE:
The `baseurl` option might be named differently in some static site generators.

Every Static Site Generator (SSG) default configuration expects
to find your website under a (sub)domain (`example.com`), not
in a subdirectory of that domain (`example.com/subdir`). Therefore,
whenever you publish a project website (for example, `namespace.gitlab.io/project-slug`),
you must look for this configuration (base URL) on your static site generator's
documentation and set it up to reflect this pattern.

For example, for a Jekyll site, the `baseurl` is defined in the Jekyll
configuration file, `_config.yml`. If your website URL is
`https://john.gitlab.io/blog/`, you need to add this line to `_config.yml`:

```yaml
baseurl: "/blog"
```

On the contrary, if you deploy your website after forking one of
our [default examples](https://gitlab.com/pages), the `baseurl` is
already configured this way, as all examples there are project
websites. If you decide to make yours a user or group website, you
must remove this configuration from your project. For the Jekyll
example we just mentioned, you must change Jekyll's `_config.yml` to:

```yaml
baseurl: ""
```

If you're using the [plain HTML example](https://gitlab.com/pages/plain-html),
you don't need to set a `baseurl`.

## Custom domains

GitLab Pages supports custom domains and subdomains, served under HTTP or HTTPS.
See [GitLab Pages custom domains and SSL/TLS Certificates](custom_domains_ssl_tls_certification/_index.md) for more information.
