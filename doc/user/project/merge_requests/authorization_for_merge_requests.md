---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "The most common merge request flows in GitLab use forks, protected branches, or both."
title: Merge request workflows
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab merge requests commonly follow one of these flows:

- Working with [protected branches](../repository/branches/protected.md) in a single repository.
- Working with forks of an authoritative project.

## Protected branch flow

With the protected branch flow, everybody works in the same GitLab project, instead of forks.

The project maintainers get the Maintainer role and the regular developers
get the Developer role.

Maintainers mark the authoritative branches as 'Protected'.

Developers push feature branches to the project and create merge requests
to have their feature branches reviewed and merged into one of the protected
branches.

By default, only users with the Maintainer role can merge changes into a
protected branch.

**Advantages**

- Fewer projects means less clutter.
- Developers need to consider only one remote repository.

**Disadvantages**

- Manual setup of protected branch required for each new project

To set up a protected branch flow:

1. Start with ensuring that your default branch is protected with [default branch protections](../repository/branches/default.md).
1. If your team has multiple branches, and you would like to manage who can merge changes and who
   explicitly has the option to push or force push, consider making those branches protected:

   - [Manage and Protect Branches](../repository/branches/_index.md#manage-and-protect-branches)
   - [Protected Branches](../repository/branches/protected.md)

1. Each change to the code comes through as a commit.
   You can specify the format and security measures such as requiring SSH key signing for changes
   coming into your codebase with push rules:

   - [Push rules](../repository/push_rules.md)

1. To ensure that the code is reviewed and checked by the right people in your team, use:

   - [Code Owners](../codeowners/_index.md)
   - [Merge request approval rules](approvals/rules.md)

Also available in the Ultimate tier:

- [Status checks](status_checks.md)
- [Security Approvals](approvals/rules.md#security-approvals)

## Forking workflow

With the forking workflow, maintainers get the Maintainer role and regular
developers get the Reporter role on the authoritative repository, which prohibits
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
important to describe those, too. Think of things that might go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
