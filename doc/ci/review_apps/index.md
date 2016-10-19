# Review apps

> [Introduced][ce-21971] in GitLab 8.12. Further additions were made in GitLab 8.13.

Review apps are automatically-created [environments] that run your code for each
branch. That means [merge requests] can be reviewed in a live-running environment.

They mostly make sense to be used with web applications.

Review Apps can make a huge impact on your development flow. Reviewing anything
from performance to interface changes becomes much easier with a live environment.

>
Inspired by [Heroku's Review Apps][heroku-apps] which itself was inspired by
[Fourchette].

## Dynamic environments

You can now use predefined CI variables as a name for environments. In addition,
you can specify a URL for the environment configuration in your .gitlab-ci.yml
file.

- Mapping branch with environment

This issue describes dynamic environments implementation, mostly to be used with dynamically create applications.
These application will be mostly used for Review Apps.

## Assumptions

1. We will allow to create dynamic environments from `.gitlab-ci.yml`, by allowing to specify environment variables: `review_apps_${CI_BUILD_REF_NAME}`,
1. We will use multiple deployments of the same application per environment,
1. The URL will be assigned to environment on the creation, and updated later if necessary,
1. The URL will be specified in `.gitlab-ci.yml`, possibly introducing regexp for getting an URL from build log if required,
1. We need some form to distinguish between production/staging and review app environment,
1. We don't try to manage life cycle of deployments in the first iteration, possibly we will extend a Pipeline to add jobs that will be responsible either for cleaning up or removing old deployments and closing environments.

## Configuration

```
review_apps:
  environment:
    name: review/$CI_BUILD_REF_NAME
    url: http://$CI_BUILD_REF_NAME.review.gitlab.com/
```

### Remarks

1. We are limited to use only CI predefined variables, since this is not easy task to pass the URL from build,
2. I do prefer nested `url:` since this allows us in the future to extend that with more `environment:` configuration or constraints, like: `required_variables:` or `access_level` of user allowed to use that.
3. Following the problem from (1) we can extend `url:` with a `regexp` that will be used to fish a URL from build log.

## Distinguish between production and review apps

### Convention over configuration

We would expect the environments to be of `type/name`:

1. This would allow us to have a clear distinction between different environment types: `production/gitlab.com`, `staging/dev`, `review-apps/feature/branch`,
2. Since we use a folder structure we could group all environments by `type` and strip that from environment name,
3. We would be aware of some of these types and for example for `review-apps` show them differently in context of Merge Requests, ex. calculating `deployed ago` a little differently.
3. We could easily group all `types` across from group from all projects.

The `type/name` also plays nice with `Variables` and `Runners`, because we can limit their usage:

1. We could extend the resources with a field that would allow us to filter for what types it can be used, ex.: `production/*` or `review-apps/*`
2. We could limit runners to be used only by `review-apps/*`,

## Destroying Review Apps


## Examples

- Use with NGINX
- Use with Amazon S3
- Use on Heroku with dpl
- Use with OpenShift/kubernetes

[ce-21971]: https://gitlab.com/gitlab-org/gitlab-ce/issues/21971
[heroku-apps]: https://devcenter.heroku.com/articles/github-integration-review-apps
[environments]: ../environments.md
[merge requests]: ../../user/project/merge_requests.md
[fourchette]: https://github.com/rainforestapp/fourchette
