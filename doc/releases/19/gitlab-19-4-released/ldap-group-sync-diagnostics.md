---
title: Diagnose LDAP group sync failures
tier: [ Premium, Ultimate ]
offering: [ self_managed ]
stage: software_supply_chain_security
co_create: true
documentation_link: "../../../administration/auth/ldap/#ldap-sync-configuration-settings"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250622
categories: [ System Access ]
level: secondary
weight: 10
---

When an LDAP group sync fails, the reason now reaches you. The failure is recorded against the
group, the members that caused it are named (up to five), and a danger alert appears on the group
members page, so a sync blocked by an email-domain restriction is diagnosable from the UI. A new
`group_filter` setting lets you narrow which LDAP entries count as groups. The audit log also
distinguishes causes that previously shared one entry: LDAP group links created and removed, and
users blocked by LDAP sync, each now get their own audit event type.

Thank you to [Sergey Pechenko](https://gitlab.com/tnt4brain) for these contributions
([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250622) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253816) [MR 3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252957) [MR 4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247146))!
