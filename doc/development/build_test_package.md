---
stage: Systems
group: Distribution
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Building a package for testing
---

While developing a new feature or modifying an existing one, it is helpful if an
installable package (or a Docker image) containing those changes is available
for testing. For this purpose, a manual job is provided in the GitLab CI/CD
pipeline that can be used to trigger a pipeline in the Omnibus GitLab repository
that will create:

- A deb package for Ubuntu 16.04, available as a build artifact, and
- A Docker image. The Docker image is pushed to the
  [Omnibus GitLab container registry](https://gitlab.com/gitlab-org/omnibus-gitlab/container_registry). Images for the GitLab Enterprise Edition are named `gitlab-ee`. Images for the GitLab Community Edition are named `gitlab-ce`.
- The image tag is the commit that triggered the pipeline.

When you push a commit to either the GitLab CE or GitLab EE project, the
pipeline for that commit will have a `trigger-omnibus` job inside `e2e:test-on-omnibus` child pipeline in the `.pre` stage.

![Trigger omnibus job](img/trigger_omnibus_v16_3.png)

After the child pipeline started, you can select `trigger-omnibus` to go to
the child pipeline named `TRIGGERED_EE_PIPELINE`.

![Triggered child pipeline](img/triggered_ee_pipeline_v16_3.png)

Next, select the `Trigger:package` job in the `trigger-package` stage.

The `Trigger:package` job when finished will upload its artifacts to GitLab, and
then you can `Browse` them and download the `.deb` file or you can use the
GitLab API to download the file straight to your VM. Keep in mind the expiry of
these artifacts is short, so they will be deleted automatically within a day or
so.

## Specifying versions of components

If you want to create a package from a specific branch, commit or tag of any of
the GitLab components (like GitLab Workhorse, Gitaly, or GitLab Pages), you
can specify the branch name, commit SHA or tag in the component's respective
`*_VERSION` file. For example, if you want to build a package that uses the
branch `0-1-stable`, modify the content of `GITALY_SERVER_VERSION` to
`0-1-stable` and push the commit. This will create a manual job that can be
used to trigger the build.

## Specifying the branch in Omnibus GitLab repository

In scenarios where a configuration change is to be introduced and Omnibus GitLab
repository already has the necessary changes in a specific branch, you can build
a package against that branch through a CI/CD variable named
`OMNIBUS_BRANCH`. To do this, specify that variable with the name of
the branch as value in `.gitlab-ci.yml` and push a commit. This will create a
manual job that can be used to trigger the build.
