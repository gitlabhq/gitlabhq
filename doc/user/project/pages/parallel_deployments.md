---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages parallel deployments
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129534) in GitLab 16.7 as an [experiment](../../../policy/development_stages_support.md) [with a flag](../../feature_flags.md) named `pages_multiple_versions_setting`. Disabled by default.
- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/480195) from "multiple deployments" to "parallel deployments" in GitLab 17.4.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/422145) in GitLab 17.4.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/502219) to remove the project setting in GitLab 17.7.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/507423) to allow periods in `path_prefix` in GitLab 17.8.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/500000) to allow variables when passed to `publish` property in GitLab 17.9.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/487161) in GitLab 17.9. Feature flag `pages_multiple_versions_setting` removed.
- Automatically appending `pages.publish` path to `artifacts:paths` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/428018) in GitLab 17.10 for Pages jobs only.

{{< /history >}}

With parallel deployments, you can publish multiple versions of your [GitLab Pages](_index.md)
site at the same time. Each version has its own unique URL based on a path prefix you specify.

Use parallel deployments to:

- Enhance your workflow for testing changes in development branches before merging
  to production.
- Share working previews with stakeholders for feedback.
- Maintain documentation for multiple software versions simultaneously.
- Publish localized content for different audiences.
- Create staging environments for review before final publication.

Each version of your site gets its own URL based on a path prefix that you specify.
Control how long these parallel deployments exist.
They expire after 24 hours by default, but you can customize this duration to fit your review timeline.

### Create a parallel deployment

Prerequisites:

- The root-level namespace must have available [parallel deployment slots](../../gitlab_com/_index.md#other-limits).

To create a parallel deployment:

1. In your `.gitlab-ci.yml` file, add a Pages job with a `path_prefix`:

   ```yaml
   pages:
     stage: deploy
     script:
       - echo "Pages accessible through ${CI_PAGES_URL}/${CI_COMMIT_BRANCH}"
     pages:  # specifies that this is a Pages job and publishes the default public directory
       path_prefix: "$CI_COMMIT_BRANCH"
   ```

   The `path_prefix` value:

   - Is converted to lowercase.
   - Can contain numbers (`0-9`), letters (`a-z`), and periods (`.`).
   - Is replaced with hyphens (`-`) for any other characters.
   - Cannot start or end with hyphens (`-`) or periods (`.`), so they are removed.
   - Must be 63 bytes or shorter. Anything longer is trimmed.

1. Optional. If you want dynamic prefixes, use
   [CI/CD variables](../../../ci/variables/where_variables_can_be_used.md#gitlab-ciyml-file) in your `path_prefix`.
   For example:

   ```yaml
   pages:
     path_prefix: "mr-$CI_MERGE_REQUEST_IID" # Results in paths like mr-123
   ```

1. Optional. To set an expiry time for the deployment, add `expire_in`:

   ```yaml
   pages:
     pages:
       path_prefix: "$CI_COMMIT_BRANCH"
       expire_in: 1 week
   ```

   By default, parallel deployments [expire](#expiration) after 24 hours.

1. Commit your changes and push to your repository.

The deployment is accessible at:

- With a [unique domain](_index.md#unique-domains): `https://project-123456.gitlab.io/your-prefix-name`.
- Without a unique domain: `https://namespace.gitlab.io/project/your-prefix-name`.

The URL path between the site domain and public directory is determined by the `path_prefix`.
For example, if your main deployment has content at `/index.html`, a parallel deployment with prefix
`staging` can access that same content at `/staging/index.html`.

To prevent path clashes, avoid using path prefixes that match the names of existing folders in your site.
For more information, see [Path clash](#path-clash).

### Example configuration

Consider a project such as `https://gitlab.example.com/namespace/project`. By default, its main Pages deployment can be accessed through:

- When using a [unique domain](_index.md#unique-domains): `https://project-123456.gitlab.io/`.
- When not using a unique domain: `https://namespace.gitlab.io/project`.

If a `pages.path_prefix` is configured to the project branch names,
like `path_prefix = $CI_COMMIT_BRANCH`, and there's a
branch named `username/testing_feature`, this parallel Pages deployment would be accessible through:

- When using a [unique domain](_index.md#unique-domains): `https://project-123456.gitlab.io/username-testing-feature`.
- When not using a unique domain: `https://namespace.gitlab.io/project/username-testing-feature`.

### Limits

The number of parallel deployments is limited by the root-level namespace. For
specific limits for:

- GitLab.com, see [Other limits](../../gitlab_com/_index.md#other-limits).
- GitLab Self-Managed, see
  [Number of parallel Pages deployments](../../../administration/instance_limits.md#number-of-parallel-pages-deployments).

To immediately reduce the number of active deployments in your namespace,
delete some deployments. For more information, see
[Delete a deployment](_index.md#delete-a-deployment).

To configure an expiry time to automatically
delete older deployments, see
[Expiring deployments](_index.md#expiring-deployments).

### Expiration

By default, parallel deployments [expire](_index.md#expiring-deployments) after 24 hours,
after which they are deleted. If you're using a self-hosted instance, your instance admin can
[configure a different default duration](../../../administration/pages/_index.md#configure-the-default-expiry-for-parallel-deployments).

To customize the expiry time, [configure `pages.expire_in`](_index.md#expiring-deployments).

To prevent deployments from automatically expiring, set `pages.expire_in` to
`never`.

### Path clash

`pages.path_prefix` can take dynamic values from [CI/CD variables](../../../ci/variables/_index.md)
that can create pages deployments which could clash with existing paths in your site.
For example, given an existing GitLab Pages site with the following paths:

```plaintext
/index.html
/documents/index.html
```

If a `pages.path_prefix` is `documents`, that version overrides the existing path.
In other words, `https://namespace.gitlab.io/project/documents/index.html` points to the
`/index.html` on the `documents` deployment of the site, instead of `documents/index.html` of the
`main` deployment of the site.

Mixing [CI/CD variables](../../../ci/variables/_index.md) with other strings can reduce the path clash
possibility. For example:

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  variables:
    PAGES_PREFIX: "" # No prefix by default (main)
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: "$PAGES_PREFIX"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH # Run on default branch (with default PAGES_PREFIX)
    - if: $CI_COMMIT_BRANCH == "staging" # Run on main (with default PAGES_PREFIX)
      variables:
        PAGES_PREFIX: '_stg' # Prefix with _stg for the staging branch
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" # Conditionally change the prefix for Merge Requests
      when: manual # Run pages manually on Merge Requests
      variables:
        PAGES_PREFIX: 'mr-$CI_MERGE_REQUEST_IID' # Prefix with the mr-<iid>, like `mr-123`
```

Some other examples of mixing [variables](../../../ci/variables/_index.md) with strings for dynamic prefixes:

- `pages.path_prefix: 'mr-$CI_COMMIT_REF_SLUG'`: Branch or tag name prefixed with `mr-`, like `mr-branch-name`.
- `pages.path_prefix: '_${CI_MERGE_REQUEST_IID}_'`: Merge request number
  prefixed ans suffixed with `_`, like `_123_`.

The previous YAML example uses [user-defined job names](_index.md#user-defined-job-names).

### Use parallel deployments to create Pages environments

You can use parallel GitLab Pages deployments to create a new [environment](../../../ci/environments/_index.md).
For example:

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  variables:
    PAGES_PREFIX: "" # no prefix by default (run on the default branch)
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: "$PAGES_PREFIX"
  environment:
    name: "Pages ${PAGES_PREFIX}"
    url: $CI_PAGES_URL
  rules:
    - if: $CI_COMMIT_BRANCH == "staging" # ensure to run on the default branch (with default PAGES_PREFIX)
      variables:
        PAGES_PREFIX: '_stg' # prefix with _stg for the staging branch
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" # conditionally change the prefix on Merge Requests
      when: manual # run pages manually on Merge Requests
      variables:
        PAGES_PREFIX: 'mr-$CI_MERGE_REQUEST_IID' # prefix with the mr-<iid>, like `mr-123`
```

With this configuration, users will have the access to each GitLab Pages deployment through the UI.
When using [environments](../../../ci/environments/_index.md) for pages, all pages environments are
listed on the project environment list.

You can also [group similar environments](../../../ci/environments/_index.md#group-similar-environments) together.

The previous YAML example uses [user-defined job names](_index.md#user-defined-job-names).

#### Auto-clean

Parallel Pages deployments, created by a merge request with a `path_prefix`, are automatically deleted when the
merge request is closed or merged.

### Usage with redirects

Redirects use absolute paths.
Because parallel deployments are available on a sub-path, redirects require
additional modifications to the `_redirects` file to work in parallel deployments.

Existing files always take priority over a redirect rule, so you can use a splat placeholder
to catch requests to prefixed paths.

If your `path_prefix` is `/mr-${$CI_MERGE_REQUEST_IID}`, adapt this `_redirect` file example
to redirect requests for both primary and parallel deployments:

```shell
# Redirect the primary deployment
/will-redirect.html /redirected.html 302

# Redirect parallel deployments
/*/will-redirect.html /:splat/redirected.html 302
```
