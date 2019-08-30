---
last_updated: 2018-06-04
type: concepts, reference
---

# Static sites and GitLab Pages domains

On this docucument, learn how to name your project for GitLab Pages
according to your intended website's URL.

## Static sites

GitLab Pages only supports static websites, meaning,
your output files must be HTML, CSS, and JavaScript only.

To create your static site, you can either hardcode in HTML,
CSS, and JS, or use a [Static Site Generator (SSG)](https://www.staticgen.com/)
to simplify your code and build the static site for you,
which is highly recommendable and much faster than hardcoding.

See the [further reading](#further-reading) section below for
references on static site concepts.

## GitLab Pages domain names

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

_Read on about [Projects for GitLab Pages and URL structure](getting_started_part_two.md)._

### Further reading

- Read through this technical overview on [Static versus Dynamic Websites](https://about.gitlab.com/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/)
- Understand [how modern Static Site Generators work](https://about.gitlab.com/2016/06/10/ssg-overview-gitlab-pages-part-2/) and what you can add to your static site
- You can use [any SSG with GitLab Pages](https://about.gitlab.com/2016/06/17/ssg-overview-gitlab-pages-part-3-examples-ci/)
- Fork an [example project](https://gitlab.com/pages) to build your website based upon
