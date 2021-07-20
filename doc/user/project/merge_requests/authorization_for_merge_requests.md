---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts
---

# Authorization for Merge requests **(FREE)**

There are two main ways to have a merge request flow with GitLab:

1. Working with [protected branches](../protected_branches.md) in a single repository.
1. Working with forks of an authoritative project.

## Protected branch flow

With the protected branch flow everybody works within the same GitLab project.

The project maintainers get the [Maintainer role](../../permissions.md) and the regular developers
get the Developer role.

Maintainers mark the authoritative branches as 'Protected'.

Developers push feature branches to the project and create merge requests
to have their feature branches reviewed and merged into one of the protected
branches.

By default, only users with the [Maintainer role](../../permissions.md) can merge changes into a
protected branch.

**Advantages**

- Fewer projects means less clutter.
- Developers need to consider only one remote repository.

**Disadvantages**

- Manual setup of protected branch required for each new project

## Forking workflow

With the forking workflow, maintainers get the [Maintainer role](../../permissions.md) and regular
developers get Reporter access to the authoritative repository, which prohibits
them from pushing any changes to it.

Developers create forks of the authoritative project and push their feature
branches to their own forks.

To get their changes into the default branch, they need to create a merge request across
forks.

**Advantages**

- In an appropriately configured GitLab group, new projects automatically get
  the required access restrictions for regular developers: fewer manual steps
  to configure authorization for new projects.

**Disadvantages**

- The project need to keep their forks up to date, which requires more advanced
  Git skills (managing multiple remotes).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
