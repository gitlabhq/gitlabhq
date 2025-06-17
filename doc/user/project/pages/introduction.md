---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages settings
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Pages offers configuration options to customize your static site's deployment and presentation.
With Pages settings, you can:

- Serve custom error pages for 403 and 404 responses.
- Configure URL redirects through `_redirects` files.
- Deploy pages from any branch using CI/CD rules.
- Serve pre-compressed assets for faster page loads.
- Customize the folder from which your site is published.
- Generate and manage unique domains for your sites.

This guide explains the settings and configuration options available for your GitLab Pages sites.
For an introduction to Pages, see [GitLab Pages](_index.md).

## GitLab Pages requirements

In brief, this is what you need to upload your website in GitLab Pages:

1. Domain of the instance: domain name that is used for GitLab Pages
   (ask your administrator).
1. GitLab CI/CD: a `.gitlab-ci.yml` file with a specific job named [`pages`](../../../ci/yaml/_index.md#pages) in the root directory of your repository.
1. GitLab Runner enabled for the project.

## GitLab Pages on GitLab.com

If you are using [GitLab Pages on GitLab.com](#gitlab-pages-on-gitlabcom) to host your website, then:

- The domain name for GitLab Pages on GitLab.com is `gitlab.io`.
- Custom domains and TLS support are enabled.
- Instance runners are enabled by default, provided for free and can be used to
  build your website. If you want you can still bring your own runner.

## Example projects

Visit the [GitLab Pages group](https://gitlab.com/groups/pages) for a complete list of example projects. Contributions are very welcome.

## Custom error codes pages

You can provide your own `403` and `404` error pages by creating `403.html` and
`404.html` files in the root of the `public/` directory. Usually this is
the root directory of your project, but that may differ
depending on your static generator configuration.

If the case of `404.html`, there are different scenarios. For example:

- If you use project Pages (served under `/project-slug/`) and try to access
  `/project-slug/non/existing_file`, GitLab Pages tries to serve first
  `/project-slug/404.html`, and then `/404.html`.
- If you use user or group Pages (served under `/`) and try to access
  `/non/existing_file` GitLab Pages tries to serve `/404.html`.
- If you use a custom domain and try to access `/non/existing_file`, GitLab
  Pages tries to serve only `/404.html`.

## Redirects in GitLab Pages

You can configure redirects for your site using a `_redirects` file. For more information, see
[Create redirects for GitLab Pages](redirects.md).

## Delete a Pages site

Permanently delete all Pages deployments for a project.
This is permanent and cannot be undone.

To delete your pages:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Deploy > Pages**.
1. Select **Delete pages**.

Your Pages site is no longer deployed.
To deploy this Pages site again, run a new pipeline.

## Subdomains of subdomains

When using Pages under the top-level domain of a GitLab instance (`*.example.io`), you can't use HTTPS with subdomains
of subdomains. If your namespace or group name contains a dot (for example, `foo.bar`) the domain
`https://foo.bar.example.io` does **not** work.

This limitation is because of the [HTTP Over TLS protocol](https://www.rfc-editor.org/rfc/rfc2818#section-3.1). HTTP pages
work as long as you don't redirect HTTP to HTTPS.

## GitLab Pages in projects and groups

You must host your GitLab Pages website in a project. This project can be
[private, internal, or public](../../public_access.md) and belong
to a [group](../../group/_index.md) or [subgroup](../../group/subgroups/_index.md).

For [group websites](getting_started_part_one.md#user-and-group-website-examples),
the group must be at the top level and not a subgroup.

For [project websites](getting_started_part_one.md#project-website-examples),
you can create your project first and access it under `http(s)://namespace.example.io/project-path`.

## Specific configuration options for Pages

Learn how to set up GitLab CI/CD for specific use cases.

### `.gitlab-ci.yml` for plain HTML websites

Suppose your repository contained the following files:

```plaintext
├── index.html
├── css
│   └── main.css
└── js
    └── main.js
```

Then the `.gitlab-ci.yml` example below moves all files from the root
directory of the project to the `public/` directory. The `.public` workaround
is so `cp` doesn't also copy `public/` to itself in an infinite loop:

```yaml
create-pages:
  script:
    - mkdir .public
    - cp -r * .public
    - mv .public public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

The previous YAML example uses [user-defined job names](_index.md#user-defined-job-names).

### `.gitlab-ci.yml` for a static site generator

See this document for a [step-by-step guide](getting_started/pages_from_scratch.md).

### `.gitlab-ci.yml` for a repository with code

Remember that GitLab Pages are by default branch/tag agnostic and their
deployment relies solely on what you specify in `.gitlab-ci.yml`. You can limit
the `pages` job with [`rules:if`](../../../ci/yaml/_index.md#rulesif),
whenever a new commit is pushed to a branch used specifically for your
pages.

That way, you can have your project's code in the `main` branch and use an
orphan branch (let's name it `pages`) to host your static generator site.

You can create a new empty branch like this:

```shell
git checkout --orphan pages
```

The first commit made on this new branch has no parents and is the root of a
new history totally disconnected from all the other branches and commits.
Push the source files of your static generator in the `pages` branch.

Below is a copy of `.gitlab-ci.yml` where the most significant line is the last
one, specifying to execute everything in the `pages` branch:

```yaml
create-pages:
  image: ruby:2.6
  script:
    - gem install jekyll
    - jekyll build -d public/
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: '$CI_COMMIT_REF_NAME == "pages"'
```

See an example that has different files in the [`main` branch](https://gitlab.com/pages/jekyll-branched/tree/main)
and the source files for Jekyll are in a [`pages` branch](https://gitlab.com/pages/jekyll-branched/tree/pages) which
also includes `.gitlab-ci.yml`.

The previous YAML example uses [user-defined job names](_index.md#user-defined-job-names).

### Serving compressed assets

Most modern browsers support downloading files in a compressed format. This
speeds up downloads by reducing the size of files.

Before serving an uncompressed file, Pages checks if the same file exists with
a `.br` or `.gz` extension. If it does, and the browser supports receiving
compressed files, it serves that version instead of the uncompressed one.

To take advantage of this feature, the artifact you upload to the Pages should
have this structure:

```plaintext
public/
├─┬ index.html
│ | index.html.br
│ └ index.html.gz
│
├── css/
│   └─┬ main.css
│     | main.css.br
│     └ main.css.gz
│
└── js/
    └─┬ main.js
      | main.js.br
      └ main.js.gz
```

This can be achieved by including a `script:` command like this in your
`.gitlab-ci.yml` pages job:

```yaml
create-pages:
  # Other directives
  script:
    # Build the public/ directory first
    - find public -type f -regex '.*\.\(htm\|html\|xml\|txt\|text\|js\|css\|svg\)$' -exec gzip -f -k {} \;
    - find public -type f -regex '.*\.\(htm\|html\|xml\|txt\|text\|js\|css\|svg\)$' -exec brotli -f -k {} \;
  pages: true  # specifies that this is a Pages job
```

By pre-compressing the files and including both versions in the artifact, Pages
can serve requests for both compressed and uncompressed content without
needing to compress files on-demand.

The previous YAML example uses [user-defined job names](_index.md#user-defined-job-names).

### Resolving ambiguous URLs

GitLab Pages makes assumptions about which files to serve when receiving a
request for a URL that does not include an extension.

Consider a Pages site deployed with the following files:

```plaintext
public/
├── index.html
├── data.html
├── info.html
├── data/
│   └── index.html
└── info/
    └── details.html
```

Pages supports reaching each of these files through several different URLs. In
particular, it always looks for an `index.html` file if the URL only
specifies the directory. If the URL references a file that doesn't exist, but
adding `.html` to the URL leads to a file that does exist, it's served
instead. Here are some examples of what happens given the previous Pages site:

| URL path             | HTTP response |
| -------------------- | ------------- |
| `/`                  | `200 OK`: `public/index.html` |
| `/index.html`        | `200 OK`: `public/index.html` |
| `/index`             | `200 OK`: `public/index.html` |
| `/data`              | `302 Found`: redirecting to `/data/` |
| `/data/`             | `200 OK`: `public/data/index.html` |
| `/data.html`         | `200 OK`: `public/data.html` |
| `/info`              | `302 Found`: redirecting to `/info/` |
| `/info/`             | `404 Not Found` Error Page |
| `/info.html`         | `200 OK`: `public/info.html` |
| `/info/details`      | `200 OK`: `public/info/details.html` |
| `/info/details.html` | `200 OK`: `public/info/details.html` |

When `public/data/index.html` exists, it takes priority over the `public/data.html` file
for both the `/data` and `/data/` URL paths.

## Customize the default folder

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/859) in GitLab 16.1 with a Pages flag named `FF_CONFIGURABLE_ROOT_DIR`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1073) in GitLab 16.1.
- [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/890) in GitLab 16.2.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/500000) to allow variables when passed to `publish` property in GitLab 17.9.
- [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/428018) the `publish` property under the `pages` keyword in GitLab 17.9.
- [Appended](https://gitlab.com/gitlab-org/gitlab/-/issues/428018) the `pages.publish` path automatically to `artifacts:paths` in GitLab 17.10.

{{< /history >}}

By default, Pages looks for a folder named `public` in your build files to publish it.

To change that folder name to any other value, add a `pages.publish` property to your
`deploy-pages` job configuration in `.gitlab-ci.yml`.

The following example publishes a folder named `dist` instead:

```yaml
create-pages:
  script:
    - npm run build
  pages:  # specifies that this is a Pages job
    publish: dist
```

The previous YAML example uses [user-defined job names](_index.md#user-defined-job-names).

To use variables in the `pages.publish` field, see [`pages.publish`](../../../ci/yaml/_index.md#pagespublish).

Pages uses artifacts to store the files of your site, so the value from
`pages.publish` is automatically appended to [`artifacts:paths`](../../../ci/yaml/_index.md#artifactspaths).
The previous example is equivalent to:

```yaml
create-pages:
  script:
    - npm run build
  pages:
    publish: dist
  artifacts:
    paths:
      - dist
```

{{< alert type="warning" >}}

The top-level `publish` keyword was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/519499) in GitLab 17.9 and must now be nested under the `pages` keyword.

{{< /alert >}}

## Regenerate unique domain for GitLab Pages

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481746) in GitLab 17.7.

{{< /history >}}

You can regenerate the unique domain for your GitLab Pages site.

After the domain is regenerated, the previous URL is no longer active.
If anyone tries to access the old URL, they'll receive a `404` error.

Prerequisites

- You must have at least the Maintainer role for the project.
- The **Use unique domain** setting [must be enabled](_index.md#unique-domains) in your project's Pages settings.

To regenerate a unique domain for your GitLab Pages site:

1. On the left sidebar, select  **Deploy > Pages**.
1. Next to **Access pages**, press **Regenerate unique domain**.
1. GitLab generates a new unique domain for your Pages site.

## Known issues

For a list of known issues, see the GitLab [public issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues?label_name[]=Category%3APages).

## Troubleshooting

### 404 error when accessing a GitLab Pages site URL

This problem most likely results from a missing `index.html` file in the public directory. If after deploying a Pages site
a 404 is encountered, confirm that the public directory contains an `index.html` file. If the file contains a different name
such as `test.html`, the Pages site can still be accessed, but the full path would be needed. For example: `https//group-name.pages.example.com/project-slug/test.html`.

The contents of the public directory can be confirmed by [browsing the artifacts](../../../ci/jobs/job_artifacts.md#download-job-artifacts) from the latest pipeline.

Files listed under the public directory can be accessed through the Pages URL for the project.

A 404 can also be related to incorrect permissions. If [Pages Access Control](pages_access_control.md) is enabled, and a user
goes to the Pages URL and receives a 404 response, it is possible that the user does not have permission to view the site.
To fix this, verify that the user is a member of the project.

### Broken relative links

GitLab Pages supports extensionless URLs. However, due to the problem
described in [issue #354](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/354),
if an extensionless URL ends in a forward slash (`/`), it breaks any relative links on the page.

To work around this issue:

- Ensure any URLs pointing to your Pages site have extensions, or do not include a trailing slash.
- If possible, use only absolute URLs on your site.

### Cannot play media content on Safari

Safari requires the web server to support the [Range request header](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingVideoforSafarioniPhone/CreatingVideoforSafarioniPhone.html#//apple_ref/doc/uid/TP40006514-SW6) to play your media content. For GitLab Pages to serve
HTTP Range requests, you should use the following two variables in your `.gitlab-ci.yml` file:

```yaml
create-pages:
  stage: deploy
  variables:
    FF_USE_FASTZIP: "true"
    ARTIFACT_COMPRESSION_LEVEL: "fastest"
  script:
    - echo "Deploying pages"
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  environment: production
```

The `FF_USE_FASTZIP` variable enables the [feature flag](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags) which is needed for [`ARTIFACT_COMPRESSION_LEVEL`](../../../ci/runners/configure_runners.md#artifact-and-cache-settings).

The previous YAML example uses [user-defined job names](_index.md#user-defined-job-names).

### `401` error when accessing private GitLab Pages sites in multiple browser tabs

When you try to access a private Pages URL in two different tabs simultaneously without prior authentication,
two different `state` values are returned for each tab.
However, in the Pages session, only the most recent `state` value is stored for the given client.
As a result, after submitting credentials, one of the tabs returns a `401 Unauthorized` error.

To resolve the `401` error, refresh the page.

### Failing `pages:deploy` job

To deploy with GitLab Pages, the root content directory must contain a non-empty `index.html` file,
or the `pages:deploy` job fails.

The content directory is `public/` by default, or a directory specified with the
`pages.publish` keyword in your `.gitlab-ci.yml` file.
