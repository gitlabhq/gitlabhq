---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Compliance features

You can configure the following GitLab features to help ensure that your GitLab
instance meets common compliance standards. Click a feature name for additional
documentation.

The [security features](../security/README.md) in GitLab may also help you meet
relevant compliance standards.

|Feature   |GitLab tier |GitLab.com | Product level |
| ---------| :--------: | :-------: | :-----------: |
|**[Restrict SSH Keys](../security/ssh_keys_restrictions.md)**<br>Control the technology and key length of SSH keys used to access GitLab|Core+||Instance|
|**[Granular user roles and flexible permissions](../user/permissions.md)**<br>Manage access and permissions with five different user roles and settings for external users. Set permissions according to people's role, rather than either read or write access to a repository. Don't share the source code with people that only need access to the issue tracker.|Core+|✓|Instance, Group, Project|
|**[Enforce TOS acceptance](../user/admin_area/settings/terms.md)**<br>Enforce your users accepting new terms of service by blocking GitLab traffic.|Core+||Instance|
|**[Email all users of a project, group, or entire server](../tools/email.md)**<br>An admin can email groups of users based on project or group membership, or email everyone using the GitLab instance. This is great for scheduled maintenance or upgrades.|Starter+|||Instance
|**[Omnibus package supports log forwarding](https://docs.gitlab.com/omnibus/settings/logs.html#udp-log-forwarding)**<br>Forward your logs to a central system.|Starter+||Instance|
|**[Lock project membership to group](../user/group/index.md#member-lock)**<br>Group owners can prevent new members from being added to projects within a group.|Starter+|✓|Group|
|**[LDAP group sync](auth/ldap/index.md#group-sync)**<br>GitLab Enterprise Edition gives admins the ability to automatically sync groups and manage SSH keys, permissions, and authentication, so you can focus on building your product, not configuring your tools.|Starter+||Instance|
|**[LDAP group sync filters](auth/ldap/index.md#group-sync)**<br>GitLab Enterprise Edition Premium gives more flexibility to synchronize with LDAP based on filters, meaning you can leverage LDAP attributes to map GitLab permissions.|Premium+||Instance|
|**[Audit events](audit_events.md)**<br>To maintain the integrity of your code, GitLab Enterprise Edition Premium gives admins the ability to view any modifications made within the GitLab server in an advanced audit events system, so you can control, analyze, and track every change.|Premium+|✓|Instance, Group, Project|
|**[Auditor users](auditor_users.md)**<br>Auditor users are users who are given read-only access to all projects, groups, and other resources on the GitLab instance.|Premium+||Instance|
|**[Credentials inventory](../user/admin_area/credentials_inventory.md)**<br>With a credentials inventory, GitLab administrators can keep track of the credentials used by all of the users in their GitLab instance. |Ultimate||Instance|
|**Separation of Duties using [Protected branches](../user/project/protected_branches.md#protected-branches-approval-by-code-owners) and [custom CI Configuration Paths](../ci/pipelines/settings.md#custom-ci-configuration-path)**<br> GitLab Silver and Premium users can leverage the GitLab cross-project YAML configurations to define deployers of code and developers of code. View the [Separation of Duties Deploy Project](https://gitlab.com/guided-explorations/separation-of-duties-deploy/blob/master/README.md) and [Separation of Duties Project](https://gitlab.com/guided-explorations/separation-of-duties/blob/master/README.md) to see how to use this set up to define these roles.|Premium+|✓|Project|
