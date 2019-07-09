# Routing

The GitLab backend is written primarily with Rails so it uses [Rails
routing](https://guides.rubyonrails.org/routing.html). Beside Rails best
practices, there are few rules unique to the GitLab application. To
support subgroups, GitLab project and group routes use the wildcard
character to match project and group routes. For example, we might have
a path such as:

```
/gitlab-com/customer-success/north-america/west/customerA
```

However, paths can be ambiguous. Consider the following example:

```
/gitlab-com/edit
```

It's ambiguous whether there is a subgroup named `edit` or whether
this is a special endpoint to edit the `gitlab-com` group.

To eliminate the ambiguity and to make the backend easier to maintain,
we introduced the `/-/` scope. The purpose of it is to separate group or
project paths from the rest of the routes. Also it helps to reduce the
number of [reserved names](../user/reserved_names.md).

## Global routes

We have a number of global routes. For example:

```
/-/health
/-/metrics
```

## Group routes

Every group route must be under the `/-/` scope.

Examples:

```
gitlab-org/-/edit
gitlab-org/-/activity
gitlab-org/-/security/dashboard
gitlab-org/serverless/-/activity
```

To achieve that, use the `scope '-'` method.

## Project routes

Every project route must be under the `/-/` scope, except cases where a Git
client or other software requires something different.

Examples:

```
gitlab-org/gitlab-ce/-/activity
gitlab-org/gitlab-ce/-/jobs/123
gitlab-org/gitlab-ce/-/settings/repository
gitlab-org/serverless/runtimes/-/settings/repository
```

Currently, only some project routes are placed under the `/-/` scope. However,
you can help us migrate more of them! To migrate project routes:

1. Modify existing routes by adding `-` scope.
1. Add redirects for legacy routes by using `Gitlab::Routing.redirect_legacy_paths`.
1. Create a technical debt issue to remove deprecated routes in later releases.

To get started, see an [example merge request](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/28435).
