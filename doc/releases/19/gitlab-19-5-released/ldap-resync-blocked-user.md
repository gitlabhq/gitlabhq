---
title: Resync an LDAP-blocked user on demand
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: security_platform
co_create: true
documentation_link: "../../../administration/moderate_users/#resync-a-user-blocked-by-ldap"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255974
categories: [ System Access ]
level: secondary
weight: 10
---

Administrators can now resync a single LDAP-blocked user from the Admin area **Users** page.
The new **Resync with LDAP** action runs an LDAP access check and unblocks the user when LDAP
allows access, or leaves the user blocked when it does not. If the user has no LDAP identity,
the action declines with a message. In previous versions of GitLab, an LDAP-blocked account
stayed blocked until the daily user sync ran or the user signed in, which service accounts
cannot do.

Thank you to [Sergey Pechenko](https://gitlab.com/tnt4brain) for this contribution ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255974))!
