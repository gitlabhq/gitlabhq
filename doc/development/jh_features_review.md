---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Guidelines for reviewing JiHu (JH) Edition related merge requests
---

We have two kinds of changes related to JH:

- Inside `jh/`
  - This is beyond EE repository and not the intention for this documentation.
- Outside `jh/`
  - These will have to sit in EE repository, so reviewers and maintainers for
    EE repository will have to review and maintain. This includes codes like
    `Gitlab.jh?`, and how it attempts to load codes under `jh/` just like we
    have codes which will load codes under `ee/`.
  - This documentation intended to guide how those codes should look like, so
    we'll have better understanding what are the changes needed for looking up
    codes under `jh/`.
  - We will generalize this so both EE and JH can share the same mechanism,
    then we wouldn't have to treat them differently.
  - Database migrations and database schema changes which are required to
    support running JH edition. See
    [JiHu guidelines for database changes](https://handbook.gitlab.com/handbook/ceo/chief-of-staff-team/jihu-support/jihu-database-change-process/)
    for details.

If needed, review the corresponding JH merge request located in the [JH repository](https://jihulab.com/gitlab-cn/gitlab).

## When to merge files to the GitLab Inc. repository

Files that are added to the GitLab JH repository outside of `jh/` must be mirrored in the GitLab Inc. repository.

If code that is added to the GitLab Inc. repository references (for example, `render_if_exists`) any GitLab JH file that does not
exist in the GitLab Inc. codebase, add a comment with a link to the JiHu merge request or file. This is to prevent
the reference from being misidentified as a missing partial and subsequently deleted in the `gitlab` codebase.

## Process overview

Read the following process guides:

- [Contribution review process](https://handbook.gitlab.com/handbook/ceo/office-of-the-ceo/jihu-support/jihu-contribution-process/)
- [Database change process](https://handbook.gitlab.com/handbook/ceo/office-of-the-ceo/jihu-support/jihu-database-change-process/)
- [Security review process](https://handbook.gitlab.com/handbook/ceo/office-of-the-ceo/jihu-support/jihu-security-review-process/)
- [Merge request process](https://handbook.gitlab.com/handbook/ceo/office-of-the-ceo/jihu-support/jihu-contribution-process/#merge-request-review-process)

## Act as EE when `jh/` does not exist or when `EE_ONLY=1`

- In the case of EE repository, `jh/` does not exist so it should just act like EE (or CE when the license is absent)
- In the case of JH repository, `jh/` does exist but `EE_ONLY` environment variable can be set to force it run under EE mode.

## Act as FOSS when `FOSS_ONLY=1`

- In the case of JH repository, `jh/` does exist but `FOSS_ONLY` environment variable can be set to force it run under FOSS (CE) mode.

## CI pipelines in a JH context

EE repository does not have `jh/` directory therefore there is no way to run
JH pipelines in the EE repository. All JH tests should go to [JH repository](https://jihulab.com/gitlab-cn/gitlab).

The top-level JH CI configuration is located at `jh/.gitlab-ci.yml` (which
does not exist in EE repository) and it'll include EE CI configurations
accordingly. Sometimes it's needed to update the EE CI configurations for JH
to customize more easily.

### JH features based on CE or EE features

For features that build on existing CE/EE features, a module in the `JH`
namespace injected in the CE/EE class/module is needed. This aligns with
what we're doing with EE features.

See [Extend CE features with EE backend code](ee_features.md#extend-ce-features-with-ee-backend-code)
for more details.

For example, to prepend a module into the `User` class you would use
the following approach:

```ruby
class User < ActiveRecord::Base
  # ... lots of code here ...
end

User.prepend_mod
```

Under EE, `User.prepend_mod` will attempt to:

- Load EE module

Under JH, `User.prepend_mod` will attempt to:

- Load EE module, and:
- Load JH module

Do not use methods such as `prepend`, `extend`, and `include`. Instead, use
`prepend_mod`, `extend_mod`, or `include_mod`. These methods will try to find
the relevant EE and JH modules by the name of the receiver module.

If reviewing the corresponding JH file is needed, it should be found at
[JH repository](https://jihulab.com/gitlab-cn/gitlab).

NOTE:
In some cases, JH does need to override something we don't need, and in that
case it is ok to also add `prepend_mod` for the modules. When we do this,
also add a comment mentioning it, and a link to the JH module using it.
This way we know where it's used and when we might not need it anymore,
and we do not remove them only because we're not using it, accidentally
breaking JH. An example of this:

```ruby
# Added for JiHu
# Used in https://jihulab.com/gitlab-cn/gitlab/-/blob/main-jh/jh/lib/jh/api/integrations.rb
API::Integrations.prepend_mod
```

### General guidance for writing JH extensions

See [Guidelines for implementing Enterprise Edition features](ee_features.md)
for general guidance.
