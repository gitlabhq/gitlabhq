---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Exploring GitLab Pages **(FREE)**

This document is a user guide to explore the options and settings
GitLab Pages offers.

To familiarize yourself with GitLab Pages first:

- Read an [introduction to GitLab Pages](index.md).
- Learn [how to get started with Pages](index.md#getting-started).
- Learn how to enable GitLab Pages
  across your GitLab instance on the [administrator documentation](../../../administration/pages/index.md).

## GitLab Pages requirements

In brief, this is what you need to upload your website in GitLab Pages:

1. Domain of the instance: domain name that is used for GitLab Pages
   (ask your administrator).
1. GitLab CI/CD: a `.gitlab-ci.yml` file with a specific job named [`pages`](../../../ci/yaml/index.md#pages) in the root directory of your repository.
1. A directory called `public` in your site's repository containing the content
   to be published.
1. GitLab Runner enabled for the project.

## GitLab Pages on GitLab.com

If you are using [GitLab Pages on GitLab.com](#gitlab-pages-on-gitlabcom) to host your website, then:

- The domain name for GitLab Pages on GitLab.com is `gitlab.io`.
- Custom domains and TLS support are enabled.
- Shared runners are enabled by default, provided for free and can be used to
  build your website. If you want you can still bring your own runner.

## Example projects

Visit the [GitLab Pages group](https://gitlab.com/groups/pages) for a complete list of example projects. Contributions are very welcome.

## Custom error codes Pages

You can provide your own 403 and 404 error pages by creating the `403.html` and
`404.html` files respectively in the root directory of the `public/` directory
that are included in the artifacts. Usually this is the root directory of
your project, but that may differ depending on your static generator
configuration.

If the case of `404.html`, there are different scenarios. For example:

- If you use project Pages (served under `/projectname/`) and try to access
  `/projectname/non/existing_file`, GitLab Pages tries to serve first
  `/projectname/404.html`, and then `/404.html`.
- If you use user/group Pages (served under `/`) and try to access
  `/non/existing_file` GitLab Pages tries to serve `/404.html`.
- If you use a custom domain and try to access `/non/existing_file`, GitLab
  Pages tries to serve only `/404.html`.

## Redirects in GitLab Pages

You can configure redirects for your site using a `_redirects` file. To learn more, read
the [redirects documentation](redirects.md).

## GitLab Pages Access Control **(FREE)**

To restrict access to your website, enable [GitLab Pages Access Control](pages_access_control.md).

## Unpublishing your Pages

If you ever feel the need to purge your Pages content, you can do so by going
to your project's settings through the gear icon in the top right, and then
navigating to **Pages**. Click the **Remove pages** button to delete your Pages
website.

![Remove pages](img/remove_pages.png)

## Limitations

When using Pages under the general domain of a GitLab instance (`*.example.io`),
you _cannot_ use HTTPS with sub-subdomains. That means that if your
username or group name contains a dot, for example `foo.bar`, the domain
`https://foo.bar.example.io` does _not_ work. This is a limitation of the
[HTTP Over TLS protocol](https://tools.ietf.org/html/rfc2818#section-3.1).
HTTP pages continue to work provided you don't redirect HTTP to HTTPS.

GitLab Pages [does **not** support group websites for subgroups](../../group/subgroups/index.md#limitations).
You can only create the highest-level group website.

## Specific configuration options for Pages

Learn how to set up GitLab CI/CD for specific use cases.

### `.gitlab-ci.yml` for plain HTML websites

Supposed your repository contained the following files:

```plaintext
├── index.html
├── css
│   └── main.css
└── js
    └── main.js
```

Then the `.gitlab-ci.yml` example below simply moves all files from the root
directory of the project to the `public/` directory. The `.public` workaround
is so `cp` doesn't also copy `public/` to itself in an infinite loop:

```yaml
pages:
  script:
    - mkdir .public
    - cp -r * .public
    - mv .public public
  artifacts:
    paths:
      - public
  only:
    - master
```

### `.gitlab-ci.yml` for a static site generator

See this document for a [step-by-step guide](getting_started/pages_from_scratch.md).

### `.gitlab-ci.yml` for a repository where there's also actual code

Remember that GitLab Pages are by default branch/tag agnostic and their
deployment relies solely on what you specify in `.gitlab-ci.yml`. You can limit
the `pages` job with the [`only` parameter](../../../ci/yaml/index.md#only--except),
whenever a new commit is pushed to a branch used specifically for your
pages.

That way, you can have your project's code in the `master` branch and use an
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
image: ruby:2.6

pages:
  script:
    - gem install jekyll
    - jekyll build -d public/
  artifacts:
    paths:
      - public
  only:
    - pages
```

See an example that has different files in the [`master` branch](https://gitlab.com/pages/jekyll-branched/tree/master)
and the source files for Jekyll are in a [`pages` branch](https://gitlab.com/pages/jekyll-branched/tree/pages) which
also includes `.gitlab-ci.yml`.

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
pages:
  # Other directives
  script:
    # Build the public/ directory first
    - find public -type f -regex '.*\.\(htm\|html\|txt\|text\|js\|css\)$' -exec gzip -f -k {} \;
    - find public -type f -regex '.*\.\(htm\|html\|txt\|text\|js\|css\)$' -exec brotli -f -k {} \;
```

By pre-compressing the files and including both versions in the artifact, Pages
can serve requests for both compressed and uncompressed content without
needing to compress files on-demand.

### Resolving ambiguous URLs

> [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/95) in GitLab 11.8

GitLab Pages makes assumptions about which files to serve when receiving a
request for a URL that does not include an extension.

Consider a Pages site deployed with the following files:

```plaintext
public/
├─┬ index.html
│ ├ data.html
│ └ info.html
│
├── data/
│   └── index.html
├── info/
│   └── details.html
└── other/
    └── index.html
```

Pages supports reaching each of these files through several different URLs. In
particular, it always looks for an `index.html` file if the URL only
specifies the directory. If the URL references a file that doesn't exist, but
adding `.html` to the URL leads to a file that *does* exist, it's served
instead. Here are some examples of what happens given the above Pages site:

| URL path             | HTTP response | File served |
| -------------------- | ------------- | ----------- |
| `/`                  | `200 OK`      | `public/index.html` |
| `/index.html`        | `200 OK`      | `public/index.html` |
| `/index`             | `200 OK`      | `public/index.html` |
| `/data`              | `200 OK`      | `public/data/index.html` |
| `/data/`             | `200 OK`      | `public/data/index.html` |
| `/data.html`         | `200 OK`      | `public/data.html` |
| `/info`              | `200 OK`      | `public/info.html` |
| `/info/`             | `200 OK`      | `public/info.html` |
| `/info.html`         | `200 OK`      | `public/info.html` |
| `/info/details`      | `200 OK`      | `public/info/details.html` |
| `/info/details.html` | `200 OK`      | `public/info/details.html` |
| `/other`             | `302 Found`   | `public/other/index.html` |
| `/other/`            | `200 OK`      | `public/other/index.html` |
| `/other/index`       | `200 OK`      | `public/other/index.html` |
| `/other/index.html`  | `200 OK`      | `public/other/index.html` |

Note that when `public/data/index.html` exists, it takes priority over the `public/data.html` file
for both the `/data` and `/data/` URL paths.

## Frequently Asked Questions

### Can I download my generated pages?

Sure. All you need to do is download the artifacts archive from the job page.

### Can I use GitLab Pages if my project is private?

Yes. GitLab Pages doesn't care whether you set your project's visibility level
to private, internal or public.

### Can I create a personal or a group website

Yes. See the documentation about [GitLab Pages domain names, URLs, and base URLs](getting_started_part_one.md).

### Do I need to create a user/group website before creating a project website?

No, you don't. You can create your project first and access it under
`http(s)://namespace.example.io/projectname`.

## Known issues

For a list of known issues, visit the GitLab [public issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues?label_name[]=Category%3APages).

## Troubleshooting

### 404 error when accessing a GitLab Pages site URL

This problem most likely results from a missing `index.html` file in the public directory. If after deploying a Pages site
a 404 is encountered, confirm that the public directory contains an `index.html` file. If the file contains a different name
such as `test.html`, the Pages site can still be accessed, but the full path would be needed. For example: `https//group-name.pages.example.com/project-name/test.html`.

The contents of the public directory can be confirmed by [browsing the artifacts](../../../ci/pipelines/job_artifacts.md#download-job-artifacts) from the latest pipeline.

Files listed under the public directory can be accessed through the Pages URL for the project.

A 404 can also be related to incorrect permissions. If [Pages Access Control](pages_access_control.md) is enabled, and a user
navigates to the Pages URL and receives a 404 response, it is possible that the user does not have permission to view the site.
To fix this, verify that the user is a member of the project.

For Geo instances, 404 errors on Pages occur after promoting a secondary to a primary.
Find more details in the [Pages administration documentation](../../../administration/pages/index.md#404-error-after-promoting-a-geo-secondary-to-a-primary-node)

### Cannot play media content on Safari

Safari requires the web server to support the [Range request header](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingVideoforSafarioniPhone/CreatingVideoforSafarioniPhone.html#//apple_ref/doc/uid/TP40006514-SW6)
in order to play your media content. For GitLab Pages to serve
HTTP Range requests, you should use the following two variables in your `.gitlab-ci.yaml` file:

```yaml
pages:
  stage: deploy
  variables:
    FF_USE_FASTZIP: "true"
    ARTIFACT_COMPRESSION_LEVEL: "fastest"
  script:
    - echo "Deploying pages"
  artifacts:
    paths:
      - public
```

The `FF_USE_FASTZIP` variable enables the [feature flag](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags) which is needed for [`ARTIFACT_COMPRESSION_LEVEL`](../../../ci/runners/configure_runners.md#artifact-and-cache-settings).
