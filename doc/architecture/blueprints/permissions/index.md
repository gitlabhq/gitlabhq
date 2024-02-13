---
status: proposed
creation-date: "2023-03-10"
authors: [ "@jessieay", "@jarka" ]
coach: "@grzesiek"
approvers: [ "@hsutor", "@adil.farrukh" ]
owning-stage: "~devops::manage"
participating-stages: []
---

# Permissions Changes required to enable Custom Roles

## Summary

Today, the GitLab permissions system is a backend implementation detail of our
static [role-based access control system](../../../user/permissions.md#roles).

In %15.9, we [announced](https://about.gitlab.com/blog/2023/03/08/expanding-guest-capabilities-in-gitlab-ultimate/)
a customer MVC of the custom roles feature. The MVC introduced the ability to
add one single permission (`read_code`) to a custom role based on a default
GitLab Guest role. The MVC was [implemented](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106256) by
taking an existing permission from the GitLab authorization framework and
enabling it if a custom role has it set to `true`.

Post-MVC, the Auth group has started work on making more permissions
customizable, with the ultimate goal of making *all* permissions customizable.

As we've started planning this work, there are two large challenges:

1. The GitLab permissions system is not a stable, backwards-compatible API.
    But [the custom roles feature is built on top of the current permissions system](https://gitlab.com/gitlab-org/gitlab/-/issues/352891#note_993031741).
    Which means that custom roles relies on permissions being a stable,
    backwards-compatible API. So we must change how we approach our permissions
    system if we plan to continue on with the current architecture.
1. Refactoring our permissions system is difficult due to the sheer number of
   permissions (over 700), duplication of permissions checks throughout the
   codebase, and the importance of permissions for security (cost
   of errors is very high).

This blueprint goes into further detail on each of these challenges and suggests
a path for addressing them.

## What are custom roles?

Our permissions system supports six default roles (Guest, Reporter, Developer, Maintainer, Owner) and users are assigned to per project or group, they can't be modified. Custom roles should solve the problem that our current system is static.

With custom roles, customers can define their own roles and give them permissions they want to. For every role they create they can assign set of permissions. For example, a newly created role "Engineer" could have `read code` and `admin merge requests` enabled but abilities such as `admin issues` disabled.

## Motivation

This plan is important to define because the [custom roles project](https://gitlab.com/groups/gitlab-org/-/epics/4035)'s
current architecture is built off of our current permissions system, [Declarative Policy](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy).
Declarative Policy makes it inexpensive to add new permissions, which has
resulted in our current state of having [over 700 permissions](https://gitlab.com/gitlab-org/gitlab/-/issues/393454#more-context)
in the `gitlab-org/gitlab` codebase. Even our [permissions documentation](../../../user/permissions.md)
contains a table with over 200 rows, each row representing a unique
"permission." Up until now, the proliferation of permissions in the code has
been manageable because these checks are not part of a public API. With custom
roles, however, that is changing.

Our current authorization checks are [often duplicated and sprinkled throughout application code](https://gitlab.com/gitlab-org/gitlab/-/issues/352891#note_958192650). For a single web request, there might be several different
permissions checked in the UI to determine if a user can see those page
elements, another few permissions checks in the Rails controller to determine if
the user can access the route at all, and maybe a few more permissions checks
sprinkled into other Ruby service classes that run as part of the page load.
This approach is [recommended in the GitLab developer documentation](../../../development/permissions/authorizations.md#where-should-permissions-be-checked)
as a "defense-in-depth" measure.

In the context of custom roles, however, this approach will not work. When a
group admin wants to enable a user to take a single action via a custom role,
that group admin should be able to toggle a single, well-named permission to
enable the user with the custom role to view or update a resource. This means
that, for a single web request, we must ensure that only one well-named
permission is checked. And, the access granted for that permission must be
relatively stable so that the admin is not giving users more access than they
think they are. Otherwise, creating and managing custom roles will be overly
complex and a security nightmare.

While the Auth group owns permissions as a feature, each team owns a set of permissions related to their domain area.
corner of the `gitlab-org/gitlab` codebase. As a result, all engineering teams that
are contributing to the `gitlab-org/gitlab` codebase touch permissions. This
means that it is even more important to provide clear guidelines on the future
of permissions and automate the enforcement of these guidelines.

### Goals

- Make it possible to customize all permissions via custom roles.
- Make the GitLab permissions system worthy of being a public API.
- Improve the naming and consistency of permissions.
- Reduce the overall number of permissions from 700+ to < 100.
- Reduce risk of refactors related to permissions.
- Make refactoring permissions easier by having a way to evaluate behavior other than unit tests and documentation.
- Track ownership of individual permissions so that DRIs can be consulted on any changes related to a permission that they own
- Create a SSoT for permissions behavior.
- Automate generation of permissions documentation.

### Non-Goals

- Pause custom roles project indefinitely while we refactor our existing permissions system (there is high demand for this as an Ultimate feature).
- Perform a total re-write or re-build of our permissions system (too much upfront investment without providing customer value).
- Iteratively work on custom roles without ever getting to feature complete ("iterate to nowhere").

## Proposal

1. Introduce a linter that ensures all new permissions adhere to naming
   conventions.
1. Reduce the overall number of permissions from 700+ to < 100 by consolidating
   our existing permissions.
1. Introduce ownership tags for each permission that requires owning group to
   review any MRs that update that permission.
1. Create a Rake task for generating permissions documentation from code so that
   we have a Single Source of Truth for permissions.

## Alternative Solutions

### Do nothing

Pros:

- No need to lengthy architecture conversation or plan
- May discover methods for improving permissions system organically as we move
  forward.

Cons:

- Slow progress in building custom role feature without blueprint for how to
  think about permissions system as a whole
- Permissions system can spiral into an unmaintainable code if we iterate on it without a strategically important vision.

### Leave the current permissions system as-is and build a parallel Declarative Policy-based system alongside it to be used for custom roles

Pros:

- Faster to design and build a new system than to do a large-scale refactor of the existing system.
- Auth team can own this new system entirely.

Cons:

- Maintaining 2 systems
- Each new "regular" permission added needs a parallel addition to the
  custom roles system. This makes it difficult to have feature parity between
  custom roles and default roles.
- Replacing our existing RBAC system with custom roles (an eventual goal of the
  custom roles feature) is more difficult with this approach because it requires
  retiring the legacy permissions system.

### Bundle existing permissions into custom permissions; use "custom permissions" for the custom roles API

Pros:

- Faster to design and build a new system than to do a large-scale refactor of the existing system.
- Auth team can own these new bundled permissions

Cons:

- Bundling permissions is less granular; the goal of custom permissions is to
  enable granular access.
- Each new "regular" permission added needs a parallel addition to the
  bundled permissions for custom roles. This makes it difficult to have feature
  parity between custom roles and default roles.

## Glossary

- **RBAC**: Role-based access control; "a method of restricting network access based
  on the roles of individual users." RBAC is the method of access control that
  GitLab uses.
- **Default roles**: the 5 categories that GitLab users can be grouped into: Guest,
  Reporter, Developer, Maintainer, Owner ([documentation](../../../user/permissions.md#roles)).
  A default role can be thought of as a group of permissions.
- **Declarative Policy**: [code library](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/)
  used by GitLab to define our authorization logic.
- **Permissions**: a specific ability that a user with a Role has. For example, a
  Developer can create merge requests but a Guest cannot. Each row listed in
  [the permissions documentation](../../../user/permissions.md#project-members-permissions)
  represents a "permission" but these may not have a 1:1 mapping with a Declarative Policy
  [ability](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/blob/main/doc/defining-policies.md#invocation).
  An ability is how permissions are represented in the GitLab codebase.
- **Access level**: integer value representing a default role, used for determining access and calculating inherited user access in group hierarchies ([documentation](../../../api/access_requests.md#valid-access-levels)).

## Resources

- [Custom Roles MVC announcement](https://github.blog/changelog/2021-10-27-enterprise-organizations-can-now-create-custom-repository-roles/)
- [Custom Roles lunch and learn notes](https://docs.google.com/document/d/1x2ExhGJl2-nEibTaQE_7e5w2sDCRRHiakrBYDspPRqw/edit#)
- [Discovery on auto-generating documentation for permissions](https://gitlab.com/gitlab-org/gitlab/-/issues/352891#note_989392294).
