---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab permissions guide

There are multiple types of permissions across GitLab, and when implementing
anything that deals with permissions, all of them should be considered.

## Groups and Projects

### General permissions

Groups and projects can have the following visibility levels:

- public (`20`) - an entity is visible to everyone
- internal (`10`) - an entity is visible to logged in users
- private (`0`) - an entity is visible only to the approved members of the entity

By default, subgroups can **not** have higher visibility levels.
For example, if you create a new private group, it can not include a public subgroup.

The visibility level of a group can be changed only if all subgroups and
sub-projects have the same or lower visibility level. For example, a group can be set
to internal only if all subgroups and projects are internal or private.

WARNING:
If you migrate an existing group to a lower visibility level, that action does not migrate subgroups
in the same way. This is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/22406).

Visibility levels can be found in the `Gitlab::VisibilityLevel` module.

### Feature specific permissions

Additionally, the following project features can have different visibility levels:

- Issues
- Repository
  - Merge Request
  - Forks
  - Pipelines
- Analytics
- Requirements
- Security & Compliance
- Wiki
- Snippets
- Pages
- Operations
- Metrics Dashboard

These features can be set to "Everyone with Access" or "Only Project Members".
They make sense only for public or internal projects because private projects
can be accessed only by project members by default.

### Members

Users can be members of multiple groups and projects. The following access
levels are available (defined in the
[`Gitlab::Access`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/access.rb)
module):

- No access (`0`)
- [Minimal access](../user/permissions.md#users-with-minimal-access) (`5`)
- Guest (`10`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`)

If a user is the member of both a project and the project parent group(s), the
higher permission is taken into account for the project.

If a user is the member of a project, but not the parent group(s), they
can still view the groups and their entities (like epics).

Project membership (where the group membership is already taken into account)
is stored in the `project_authorizations` table.

WARNING:
Due to [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/219299),
projects in personal namespace do not show owner (`50`) permission in
`project_authorizations` table. Note however that [`user.owned_projects`](https://gitlab.com/gitlab-org/gitlab/-/blob/0d63823b122b11abd2492bca47cc26858eee713d/app/models/user.rb#L906-916)
is calculated properly.

### Confidential issues

Confidential issues can be accessed only by project members who are at least
reporters (they can't be accessed by guests). Additionally they can be accessed
by their authors and assignees.

### Licensed features

Some features can be accessed only if the user has the correct license plan.

## Permission dependencies

Feature policies can be quite complex and consist of multiple rules.
Quite often, one permission can be based on another.

Designing good permissions means reusing existing permissions as much as possible
and making access to features granular.

In the case of a complex resource, it should be broken into smaller pieces of information
and each piece should be granted a different permission.

A good example in this case is the _Merge Request widget_ and the _Security reports_.
Depending on the visibility level of the _Pipelines_, the _Security reports_ are either visible
in the widget or not. So, the _Merge Request widget_, the _Pipelines_, and the _Security reports_,
have separate permissions. Moreover, the permissions for the _Merge Request widget_
and the _Pipelines_ are dependencies of the _Security reports_.

### Permission dependencies of Secure features

Secure features have complex permissions since these features are integrated
into different features like Merge Requests and CI flow.

 Here is a list of some permission dependencies.

| Activity level | Resource | Locations |Permission dependency|
|----------------|----------|-----------|-----|
| View | License information | Dependency list, License Compliance | Can view repository |
| View | Dependency information | Dependency list, License Compliance | Can view repository |
| View | Vulnerabilities information | Dependency list | Can view security findings |
| View | Black/Whitelisted licenses for the project | License Compliance, Merge request  | Can view repository |
| View | Security findings | Merge Request, CI job page, Pipeline security tab | Can read the project and CI jobs |
| View | Vulnerability feedback | Merge Request | Can read security findings |
| View | Dependency List page | Project | Can access Dependency information |
| View | License Compliance page | Project | Can access License information|

## Where should permissions be checked?

By default, controllers, API endpoints, and GraphQL types/fields are responsible for authorization. See [Secure Coding Guidelines > Permissions](secure_coding_guidelines.md#permissions).

### Considerations

- Many actions are completely or partially extracted to services, finders, and other classes, so it is normal to do permission checks "downstream".
- Often, authorization logic must be incorporated in DB queries to filter records.
- `DeclarativePolicy` rules are relatively performant, but conditions may perform database calls.
- Multiple permission checks across layers can be difficult to reason about, which is its own security risk. For example, duplicate authorization logic could diverge.
- Should we apply defense-in-depth with permission checks? [Join the discussion](https://gitlab.com/gitlab-org/gitlab/-/issues/324135)

### Tips

If a class accepts `current_user`, then it may be responsible for authorization.

### Example: Adding a new API endpoint

By default, we authorize at the endpoint. Checking an existing ability may make sense; if not, then we probably need to add one.

As an aside, most endpoints can be cleanly categorized as a CRUD (create, read, update, destroy) action on a resource. The services and abilities follow suit, which is why many are named like `Projects::CreateService` or `:read_project`.

Say, for example, we extract the whole endpoint into a service. The `can?` check will now be in the service. Say the service reuses an existing finder, which we are modifying for our purposes. Should we make the finder check an ability?

- If the finder doesn't accept `current_user`, and therefore doesn't check permissions, then probably no.
- If the finder accepts `current_user`, and doesn't check permissions, then it would be a good idea to double check other usages of the finder, and we might consider adding authorization.
- If the finder accepts `current_user`, and already checks permissions, then either we need to add our case, or the existing checks are appropriate.
