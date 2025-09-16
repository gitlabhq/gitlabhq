---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User permissions
description: User types, roles, permissions, membership, custom roles, and access controls.
---

GitLab uses a comprehensive permissions system that combines user types, roles, and membership
to control what you can do within projects and groups. Users are assigned roles that define their permissions in
projects and groups.
Memberships and associated permissions cascade from top-level groups to subgroups and their projects.

User types have different levels of access across your GitLab instance, from regular
users with standard permissions to administrators with full system control. Users can also have
custom roles with specific permissions tailored to your organizational needs.

## User types

{{< cards >}}

- [Auditor users](../administration/auditor_users.md)
- [External users](../administration/external_users.md)
- [Internal users](../administration/internal_users.md)

{{< /cards >}}

## Roles and permissions

{{< cards >}}

- [Roles and permissions](../user/permissions.md)
- [Guest role](../administration/guest_users.md)
- [Custom roles](../user/custom_roles/_index.md)
- [Custom permissions](../user/custom_roles/abilities.md)

{{< /cards >}}
