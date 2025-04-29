---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Information exclusivity
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Git is a distributed version control system (DVCS). This means that everyone
who works with the source code has a local copy of the complete repository.

In GitLab every project member that is not a guest (reporters, developers, and
maintainers) can clone the repository to create a local copy. After obtaining
a local copy, the user can upload the full repository anywhere, including to
another project that is under their control, or onto another server.

Therefore, it is impossible to build access controls that prevent the
intentional sharing of source code by users that have access to the source code.

This is an inherent feature of a DVCS. All Git management systems have this
limitation.

You can take steps to prevent unintentional sharing and information
destruction. This limitation is the reason why only certain people are allowed
to [add users to a project](../user/project/members/_index.md)
and why only a GitLab administrator can
[force push a protected branch](../user/project/repository/branches/protected.md).
