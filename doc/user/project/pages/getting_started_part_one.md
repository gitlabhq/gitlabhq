---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Pages domain names, URLs, and base URLs **(FREE)**

On this document, learn how to name your project for GitLab Pages
according to your intended website's URL.

## GitLab Pages default domain names

If you use your own GitLab instance to deploy your site with GitLab Pages, verify your Pages
wildcard domain with your sysadmin. This guide is valid for any GitLab instance, provided that you
replace the Pages wildcard domain on GitLab.com (`*.gitlab.io`) with your own.

If you set up a GitLab Pages project on GitLab,
it's automatically accessible under a
subdomain of `namespace.example.io`.
The [`namespace`](../../group/index.md#namespaces)
is defined by your username on GitLab.com,
or the group name you created this project under.
For GitLab self-managed instances, replace `example.io`
with your instance's Pages domain. For GitLab.com,
Pages domains are `*.gitlab.io`.

| Type of GitLab Pages | The name of the project created in GitLab | Website URL |
| -------------------- | ------------ | ----------- |
| User pages  | `username.example.io`  | `http(s)://username.example.io`  |
| Group pages | `groupname.example.io` | `http(s)://groupname.example.io` |
| Project pages owned by a user  | `projectname` | `http(s)://username.example.io/projectname` |
| Project pages owned by a group | `projectname` | `http(s)://groupname.example.io/projectname`|
| Project pages owned by a subgroup | `subgroup/projectname` | `http(s)://groupname.example.io/subgroup/projectname`|

WARNING:
There are some known [limitations](introduction.md#limitations)
regarding namespaces served under the general domain name and HTTPS.
Make sure to read that section.

To understand Pages domains clearly, read the examples below.

### Project website examples

- You created a project called `blog` under your username `john`,
  therefore your project URL is `https://gitlab.com/john/blog/`.
  Once you enable GitLab Pages for this project, and build your site,
  you can access it at `https://john.gitlab.io/blog/`.
- You created a group for all your websites called `websites`,
  and a project within this group is called `blog`. Your project
  URL is `https://gitlab.com/websites/blog/`. Once you enable
  GitLab Pages for this project, the site is available at
  `https://websites.gitlab.io/blog/`.
- You created a group for your engineering department called `engineering`,
  a subgroup for all your documentation websites called `docs`,
  and a project within this subgroup is called `workflows`. Your project
  URL is `https://gitlab.com/engineering/docs/workflows/`. Once you enable
  GitLab Pages for this project, the site is available at
  `https://engineering.gitlab.io/docs/workflows`.

### User and Group website examples

- Under your username, `john`, you created a project called
  `john.gitlab.io`. Your project URL is `https://gitlab.com/john/john.gitlab.io`.
  Once you enable GitLab Pages for your project, your website
  is published under `https://john.gitlab.io`.
- Under your group `websites`, you created a project called
  `websites.gitlab.io`. Your project's URL is `https://gitlab.com/websites/websites.gitlab.io`.
  Once you enable GitLab Pages for your project,
  your website is published under `https://websites.gitlab.io`.

**General example:**

- On GitLab.com, a project site is always available under
  `https://namespace.gitlab.io/project-name`
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
whenever you publish a project website (`namespace.gitlab.io/project-name`),
you must look for this configuration (base URL) on your SSG's
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
See [GitLab Pages custom domains and SSL/TLS Certificates](custom_domains_ssl_tls_certification/index.md) for more information.
