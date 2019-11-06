---
last_updated: 2018-06-04
type: concepts, reference
---

# GitLab Pages domain names, URLs, and baseurls

On this document, learn how to name your project for GitLab Pages
according to your intended website's URL.

## GitLab Pages default domain names

>**Note:**
If you use your own GitLab instance to deploy your
site with GitLab Pages, check with your sysadmin what's your
Pages wildcard domain. This guide is valid for any GitLab instance,
you just need to replace Pages wildcard domain on GitLab.com
(`*.gitlab.io`) with your own.

If you set up a GitLab Pages project on GitLab,
it will automatically be accessible under a
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

CAUTION: **Warning:**
There are some known [limitations](introduction.md#limitations)
regarding namespaces served under the general domain name and HTTPS.
Make sure to read that section.

To understand Pages domains clearly, read the examples below.

### Project website examples

- You created a project called `blog` under your username `john`,
  therefore your project URL is `https://gitlab.com/john/blog/`.
  Once you enable GitLab Pages for this project, and build your site,
  it will be available under `https://john.gitlab.io/blog/`.
- You created a group for all your websites called `websites`,
  and a project within this group is called `blog`. Your project
  URL is `https://gitlab.com/websites/blog/`. Once you enable
  GitLab Pages for this project, the site will live under
  `https://websites.gitlab.io/blog/`.
- You created a group for your engineering department called `engineering`,
  a subgroup for all your documentation websites called `docs`,
  and a project within this subgroup is called `workflows`. Your project
  URL is `https://gitlab.com/engineering/docs/workflows/`. Once you enable
  GitLab Pages for this project, the site will live under
  `https://engineering.gitlab.io/docs/workflows`.

### User and Group website examples

- Under your username, `john`, you created a project called
  `john.gitlab.io`. Your project URL will be `https://gitlab.com/john/john.gitlab.io`.
  Once you enable GitLab Pages for your project, your website
  will be published under `https://john.gitlab.io`.
- Under your group `websites`, you created a project called
  `websites.gitlab.io`. your project's URL will be `https://gitlab.com/websites/websites.gitlab.io`.
  Once you enable GitLab Pages for your project,
  your website will be published under `https://websites.gitlab.io`.

**General example:**

- On GitLab.com, a project site will always be available under
  `https://namespace.gitlab.io/project-name`
- On GitLab.com, a user or group website will be available under
  `https://namespace.gitlab.io/`
- On your GitLab instance, replace `gitlab.io` above with your
  Pages server domain. Ask your sysadmin for this information.

## URLs and baseurls

Every Static Site Generator (SSG) default configuration expects
to find your website under a (sub)domain (`example.com`), not
in a subdirectory of that domain (`example.com/subdir`). Therefore,
whenever you publish a project website (`namespace.gitlab.io/project-name`),
you'll have to look for this configuration (base URL) on your SSG's
documentation and set it up to reflect this pattern.

For example, for a Jekyll site, the `baseurl` is defined in the Jekyll
configuration file, `_config.yml`. If your website URL is
`https://john.gitlab.io/blog/`, you need to add this line to `_config.yml`:

```yaml
baseurl: "/blog"
```

On the contrary, if you deploy your website after forking one of
our [default examples](https://gitlab.com/pages), the baseurl will
already be configured this way, as all examples there are project
websites. If you decide to make yours a user or group website, you'll
have to remove this configuration from your project. For the Jekyll
example we've just mentioned, you'd have to change Jekyll's `_config.yml` to:

```yaml
baseurl: ""
```

## Custom domains

GitLab Pages supports custom domains and subdomains, served under HTTP or HTTPS.
See [GitLab Pages custom domains and SSL/TLS Certificates](custom_domains_ssl_tls_certification/index.md) for more information.
