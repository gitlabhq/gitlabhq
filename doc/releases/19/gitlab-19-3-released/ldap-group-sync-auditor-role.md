---
title: LDAP group sync can now manage the Auditor role
tier: [ Premium, Ultimate ]
offering: [ self_managed ]
stage: software_supply_chain_security
co_create: true
documentation_link: "../../../administration/auth/ldap/ldap_synchronization/#assign-an-auditor-role-to-an-ldap-group"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247042
categories: [ System Access ]
level: secondary
---

You can now use LDAP group sync for GitLab Self-Managed instances to grant and revoke the
Auditor role automatically. A new `audit_group` setting maps an LDAP group to Auditor, working
the same way `admin_group` already did for administrators, so auditor access follows directory
membership instead of being maintained by hand.

Thank you to [Sergey Pechenko](https://gitlab.com/tnt4brain) for this contribution!
