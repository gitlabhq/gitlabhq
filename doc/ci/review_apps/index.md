# Getting started with Review Apps

> - [Introduced][ce-21971] in GitLab 8.12. Further additions were made in GitLab
>   8.13 and 8.14.
> - Inspired by [Heroku's Review Apps][heroku-apps] which itself was inspired by
>  [Fourchette].

The basis of Review Apps is the [dynamic environments] which allow you to create
a new environment (dynamically) for each one of your branches.

A Review App can then be visible as a link when you visit the [merge request]
relevant to the branch. That way, you are able to see live all changes introduced
by the merge request changes. Reviewing anything, from performance to interface
changes, becomes much easier with a live environment and as such, Review Apps
can make a huge impact on your development flow.

They mostly make sense to be used with web applications, but you can use them
any way you'd like.

## Overview

Simply put, a Review App is a mapping of a branch with an environment as there
is a 1:1 relation between them.

Here's an example of what it looks like when viewing a merge request with a
dynamically set environment.

![Review App in merge request](img/review_apps_preview_in_mr.png)

In the image above you can see that the `add-new-line` branch was successfully
built and deployed under a dynamic environment and can be previewed with an
also dynamically URL.

The details of the Review Apps implementation depend widely on your real
technology stack and on your deployment process. The simplest case is to
deploy a simple static HTML website, but it will not be that straightforward
when your app is using a database for example. To make a branch be deployed
on a temporary instance and booting up this instance with all required software
and services automatically on the fly is not a trivial task. However, it is
doable, especially if you use Docker, or at least a configuration management
tool like Chef, Puppet, Ansible or Salt.

## Prerequisites

To get a better understanding of Review Apps, you must first learn how
environments and deployments work. The following docs will help you grasp that
knowledge:

1. First, learn about [environments][] and their role in the development workflow.
1. Then make a small stop to learn about [CI variables][variables] and how they
   can be used in your CI jobs.
1. Next, explore the [`environment` syntax][yaml-env] as defined in `.gitlab-ci.yml`.
   This will be your primary reference when you are finally comfortable with
   how environments work.
1. Additionally, find out about [manual actions][] and how you can use them to
   deploy to critical environments like production with the push of a button.
1. And as a last step, follow the [example tutorials](#examples) which will
   guide you step by step to set up the infrastructure and make use of
   Review Apps.

## Configuration

The configuration of Review apps depends on your technology stack and your
infrastructure. Read the [dynamic environments] documentation to understand
how to define and create them.

## Creating and destroying Review Apps

The creation and destruction of a Review App is defined in `.gitlab-ci.yml`
at a job level under the `environment` keyword.

Check the [environments] documentation how to do so.

## A simple workflow

The process of adding Review Apps in your workflow would look like:

1. Set up the infrastructure to host and deploy the Review Apps.
1. [Install][install-runner] and [configure][conf-runner] a Runner that does
   the deployment.
1. Set up a job in `.gitlab-ci.yml` that uses the predefined
   [predefined CI environment variable][variables] `${CI_COMMIT_REF_NAME}` to
   create dynamic environments and restrict it to run only on branches.
1. Optionally set a job that [manually stops][manual-env] the Review Apps.

From there on, you would follow the branched Git flow:

1. Push a branch and let the Runner deploy the Review App based on the `script`
   definition of the dynamic environment job.
1. Wait for the Runner to build and/or deploy your web app.
1. Click on the link that's present in the MR related to the branch and see the
   changes live.

## Limitations

Check the [environments limitations](../environments.md#limitations).

## Examples

A list of examples used with Review Apps can be found below:

- [Use with NGINX][app-nginx] - Use NGINX and the shell executor of GitLab Runner
  to deploy a simple HTML website.

And below is a soon to be added examples list:

- Use with Amazon S3
- Use on Heroku with dpl
- Use with OpenShift/kubernetes

[app-nginx]: https://gitlab.com/gitlab-examples/review-apps-nginx
[ce-21971]: https://gitlab.com/gitlab-org/gitlab-ce/issues/21971
[dynamic environments]: ../environments.md#dynamic-environments
[environments]: ../environments.md
[fourchette]: https://github.com/rainforestapp/fourchette
[heroku-apps]: https://devcenter.heroku.com/articles/github-integration-review-apps
[manual actions]: ../environments.md#manual-actions
[merge request]: ../../user/project/merge_requests.md
[variables]: ../variables/README.md
[yaml-env]: ../yaml/README.md#environment
[install-runner]: https://docs.gitlab.com/runner/install/
[conf-runner]: https://docs.gitlab.com/runner/commands/
[manual-env]: ../environments.md#stopping-an-environment
