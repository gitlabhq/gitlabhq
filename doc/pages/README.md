# GitLab Pages

_**Note:** This feature was [introduced][ee-80] in GitLab EE 8.3_

With GitLab Pages you can host for free your static websites on GitLab.
Combined with the power of GitLab CI and the help of GitLab Runner you can
deploy static pages for your individual projects, your user or your group.

## Enable the pages feature in your GitLab EE instance

The administrator guide is located at [administration](administration.md).

## Understanding how GitLab Pages work

GitLab Pages rely heavily on GitLab CI and its ability to upload artifacts.
The steps that are performed from the initialization of a project to the
creation of the static content, can be summed up to:

1. Create project (its name could be specific according to the case)
1. Provide a specific job in `.gitlab-ci.yml`
1. GitLab Runner builds the project
1. GitLab CI uploads the artifacts
1. Nginx serves the content

As a user, you should normally be concerned only with the first three items.
If [shared runners](../ci/runners/README.md) are enabled by your GitLab
administrator, you should be able to use them instead of bringing your own.

In general there are four kinds of pages one might create. This is better
explained with an example so let's make some assumptions.

The domain under which the pages are hosted is named `example.com`. There is a
user with the username `walter` and they are the owner of an organization named
`therug`. The personal project of `walter` is named `area51` and don't forget
that the organization has also a project under its namespace, called
`welovecats`.

The following table depicts what the project's name should be and under which
URL it will be accessible.

| Pages type | Repository name | URL schema |
| ---------- | --------------- | ---------- |
| User page  | `walter/walter.example.com`  | `https://walter.example.com`  |
| Group page | `therug/therug.example.com`  | `https://therug.example.com`  |
| Specific project under a user's page  | `walter/area51`     | `https://walter.example.com/area51`     |
| Specific project under a group's page | `therug/welovecats` | `https://therug.example.com/welovecats` |

## Group pages

To create a page for a group, add a new project to it. The project name must be lowercased.

For example, if you have a group called `TheRug` and pages are hosted under `Example.com`,
create a project named `therug.example.com`.

## Enable the pages feature in your project

The GitLab Pages feature needs to be explicitly enabled for each project
under its **Settings**.

## Remove the contents of your pages

Pages can be explicitly removed from a project by clicking **Remove Pages**
in a project's **Settings**.

## Explore the contents of .gitlab-ci.yml

Before reading this section, make sure you familiarize yourself with GitLab CI
and the specific syntax of[`.gitlab-ci.yml`](../ci/yaml/README.md) by
following our [quick start guide](../ci/quick_start/README.md).

---

To make use of GitLab Pages, your `.gitlab-ci.yml` must follow the rules below:

1. A special `pages` job must be defined
1. Any static content must be placed under a `public/` directory
1. `artifacts` with a path to the `public/` directory must be defined

Be aware that Pages are by default branch/tag agnostic and their deployment
relies solely on what you specify in `.gitlab-ci.yml`. If you don't limit the
`pages` job with the [`only` parameter](../ci/yaml/README.md#only-and-except),
whenever a new commit is pushed to whatever branch or tag, the Pages will be
overwritten. In the examples below, we limit the Pages to be deployed whenever
a commit is pushed only on the `master` branch, which is advisable to do so.

The pages are created after the build completes successfully and the artifacts
for the `pages` job are uploaded to GitLab.

The example below uses [Jekyll][] and generates the created HTML files
under the `public/` directory.

```yaml
image: ruby:2.1

pages:
  script:
  - gem install jekyll
  - jekyll build -d public/
  artifacts:
    paths:
    - public
  only:
  - master
```

The example below doesn't use any static site generator, but simply moves all
files from the root of the project to the `public/` directory. The `.public`
workaround is so `cp` doesn’t also copy `public/` to itself in an infinite
loop.

```yaml
pages:
  stage: deploy
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

## Example projects

Below is a list of example projects for GitLab Pages with a plain HTML website
or various static site generators. Contributions are very welcome.

* [Plain HTML](https://gitlab.com/gitlab-examples/pages-plain-html)
* [Jekyll](https://gitlab.com/gitlab-examples/pages-jekyll)

## Custom error codes pages

You can provide your own 403 and 404 error pages by creating the `403.html` and
`404.html` files respectively in the `public/` directory that will be included
in the artifacts.

## Frequently Asked Questions

**Q: Can I download my generated pages?**

Sure. All you need to do is download the artifacts archive from the build page.

---

[jekyll]: http://jekyllrb.com/
[ee-80]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/80
