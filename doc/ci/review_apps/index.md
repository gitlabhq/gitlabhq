# Getting started with Review Apps

> [Introduced][ce-21971] in GitLab 8.12. Further additions were made in GitLab 8.13.
>
Inspired by [Heroku's Review Apps][heroku-apps] which itself was inspired by
[Fourchette].

The base of Review Apps is the [dynamic environments] which allow you to create
a new environment (dynamically) for each one of your branches.

A Review App can then be visible as a link when you visit the [merge request]
relevant to the branch. That way, you are able to see live all changes introduced
by the merge request changes. Reviewing anything, from performance to interface
changes, becomes much easier with a live environment and as such, Review Apps
can make a huge impact on your development flow.

They mostly make sense to be used with web applications, but you can use them
any way you'd like.

## Overview

Simply put, a Review App is a mapping of
a branch with an environment as there is a 1:1 relation between them.

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
1. And as a last step, follow the [NGINX example tutorial][app-nginx] which will
   guide you step by step to set up the infrastructure and make use of
   Review Apps with a simple HTML site and NGINX.

## Configuration

For configuration examples see the [dynamic environments] documentation.

## Creating and destroying Review Apps

The creation and destruction of a Review App is defined in `.gitlab-ci.yml`.
Check the [environments] documentation how to do so.

## A simple workflow

The process of adding Review Apps in your workflow would look like:

1. Set up the infrastructure to host and deploy the Review Apps.
1. Install and configure a Runner that does the deployment.
1. Set up a job in `.gitlab-ci.yml` that uses the predefined
   [predefined CI environment variable][variables] `${CI_BUILD_REF_NAME}` to
   create dynamic environments and restrict it to run only on branches.
1. Optionally set a job that stops the Review Apps.

From there on, you would follow the branched Git flow:

1. Push a branch and let the Runner deploy the Review App based on the `script`
   definition of the dynamic environment job.
1. Wait for the Runner to build and/or deploy your web app.
1. Click on the link that's present in the MR related to the branch and see the
   changes live.

### Limitations

We are limited to use only [CI predefined variables][variables].

## Examples

A list of examples used with Review Apps can be found below:

- [Use with NGINX][app-nginx] - Use NGINX and the shell executor of GitLab Runner
  to deploy a simple HTML website.

And below is a soon to be added examples list:

- Use with Amazon S3
- Use on Heroku with dpl
- Use with OpenShift/kubernetes

## Assumptions

1. We will allow to create dynamic environments from `.gitlab-ci.yml`, by allowing to specify environment variables: `review_apps_${CI_BUILD_REF_NAME}`,
1. We will use multiple deployments of the same application per environment,
1. The URL will be assigned to environment on the creation, and updated later if necessary,
1. The URL will be specified in `.gitlab-ci.yml`, possibly introducing regexp for getting an URL from build log if required,
1. We need some form to distinguish between production/staging and review app environment,
1. We don't try to manage life cycle of deployments in the first iteration, possibly we will extend a Pipeline to add jobs that will be responsible either for cleaning up or removing old deployments and closing environments.

## Distinguish between production and review apps

- Are dynamic environments distinguishable by the slash in `environment:url`?

### Convention over configuration

We would expect the environments to be of `type/name`:

1. This would allow us to have a clear distinction between different environment types: `production/gitlab.com`, `staging/dev`, `review-apps/feature/branch`,
2. Since we use a folder structure we could group all environments by `type` and strip that from environment name,
3. We would be aware of some of these types and for example for `review-apps` show them differently in context of Merge Requests, ex. calculating `deployed ago` a little differently.
3. We could easily group all `types` across from group from all projects.

The `type/name` also plays nice with `Variables` and `Runners`, because we can limit their usage:

1. We could extend the resources with a field that would allow us to filter for what types it can be used, ex.: `production/*` or `review-apps/*`
2. We could limit runners to be used only by `review-apps/*`,

[app-nginx]: nginx_guide.md
[ce-21971]: https://gitlab.com/gitlab-org/gitlab-ce/issues/21971
[dynamic environments]: ../environments.md#dynamic-environments
[environments]: ../environments.md
[fourchette]: https://github.com/rainforestapp/fourchette
[heroku-apps]: https://devcenter.heroku.com/articles/github-integration-review-apps
[manual actions]: ../environments.md#manual-actions
[merge request]: ../../user/project/merge_requests.md
[variables]: ../variables/README.md
[yaml-env]: ../yaml/README.md#environment
