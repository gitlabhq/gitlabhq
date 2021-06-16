---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Routing

The GitLab backend is written primarily with Rails so it uses [Rails
routing](https://guides.rubyonrails.org/routing.html). Beside Rails best
practices, there are few rules unique to the GitLab application. To
support subgroups, GitLab project and group routes use the wildcard
character to match project and group routes. For example, we might have
a path such as:

```plaintext
/gitlab-com/customer-success/north-america/west/customerA
```

However, paths can be ambiguous. Consider the following example:

```plaintext
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

```plaintext
/-/health
/-/metrics
```

## Group routes

Every group route must be under the `/-/` scope.

Examples:

```plaintext
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

```plaintext
gitlab-org/gitlab/-/activity
gitlab-org/gitlab/-/jobs/123
gitlab-org/gitlab/-/settings/repository
gitlab-org/serverless/runtimes/-/settings/repository
```

## Changing existing routes

Don't change a URL to an existing page, unless it's necessary. If you must make a change,
make it unnoticeable for users, because we don't want them to receive `404 Not Found`
if we can avoid it. This table should help:

| URL description | Example  | What to do  |
|---|---|---|
| Can be used in scripts and automation | `snippet#raw` | Support both an old and new URL for one major release. Then, support a redirect from an old URL to a new URL for another major release. |
| Likely to be saved or shared | `issue#show` | Add a redirect from an old URL to a new URL until the next major release. |
| Limited use, unlikely to be shared | `admin#labels` | No extra steps required. |

## Migrating unscoped routes

Currently, the majority of routes are placed under the `/-/` scope. However,
you can help us migrate the rest of them! To migrate routes:

1. Modify existing routes by adding `-` scope.
1. Add redirects for legacy routes by using `Gitlab::Routing.redirect_legacy_paths`.
1. Create a technical debt issue to remove deprecated routes in later releases.

To get started, see an [example merge request](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/28435).

## Useful links

- [Routing improvements master plan](https://gitlab.com/gitlab-org/gitlab/-/issues/215362)
- [Scoped routing explained](https://gitlab.com/gitlab-org/gitlab/-/issues/214217)
- [Removal of deprecated routes](https://gitlab.com/gitlab-org/gitlab/-/issues/28848)
