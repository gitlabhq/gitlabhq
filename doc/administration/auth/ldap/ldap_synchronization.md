---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: LDAP synchronization
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

If you have [configured LDAP to work with GitLab](_index.md), GitLab can automatically synchronize
users and groups.

LDAP synchronization updates user and group information for existing GitLab users that have an LDAP identity assigned. It does not create new GitLab users through LDAP.

You can change when synchronization occurs.

## LDAP servers with rate limits

Some LDAP servers have rate limits configured.

GitLab queries the LDAP server once for every:

- User during the scheduled [user sync](#user-sync) process.
- Group during the scheduled [group sync](#group-sync) process.

In some cases, more queries to the LDAP server may be triggered. For example, when a [group sync query returns a `memberuid` attribute](#queries).

If the LDAP server has a rate limit configured and that limit is reached during the:

- User sync process, the LDAP server responds with an error code and GitLab blocks that user.
- Group sync process, the LDAP server responds with an error code and GitLab removes that user's group memberships.

You must consider your LDAP server's rate limits when configuring LDAP synchronization to prevent unwanted user blocks and group membership removals.

## User sync

> - Preventing LDAP user's profile name synchronization [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11336) in GitLab 15.11.

Once per day, GitLab runs a worker to check and update GitLab
users against LDAP.

The process executes the following access checks:

- Ensure the user is still present in LDAP.
- If the LDAP server is Active Directory, ensure the user is active (not
  blocked/disabled state). This check is performed only if
  `active_directory: true` is set in the LDAP configuration.

In Active Directory, a user is marked as disabled/blocked if the user
account control attribute (`userAccountControl:1.2.840.113556.1.4.803`)
has bit 2 set.

<!-- vale gitlab_base.Spelling = NO -->

For more information, see [Bitmask Searches in LDAP](https://ctovswild.com/2009/09/03/bitmask-searches-in-ldap/).

<!-- vale gitlab_base.Spelling = YES -->

The process also updates the following user information:

- Name. Because of a [sync issue](https://gitlab.com/gitlab-org/gitlab/-/issues/342598), `name` is not synchronized if
  [**Prevent users from changing their profile name**](../../settings/account_and_limit_settings.md#disable-user-profile-name-changes) is enabled or `sync_name` is set to `false`.
- Email address.
- SSH public keys if `sync_ssh_keys` is set.
- Kerberos identity if Kerberos is enabled.

NOTE:
If your LDAP server has a rate limit, that limit might be reached during the user sync process. Check the [rate limit documentation](#ldap-servers-with-rate-limits) for more information.

### Synchronize LDAP user's profile name

By default, GitLab synchronizes the LDAP user's profile name field.

To prevent this synchronization, you can set `sync_name` to `false`.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'sync_name' => false,
       }
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             sync_name: false
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'sync_name' => false,
               }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           sync_name: false
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Blocked users

A user is blocked if either the:

- [Access check fails](#user-sync) and that user is set to an `ldap_blocked` state in GitLab.
- LDAP server is not available when that user signs in.

If a user is blocked, that user cannot sign in or push or pull code.

A blocked user is unblocked when they sign in with LDAP if all of the following are true:

- All the access check conditions are true.
- The LDAP server is available when the user signs in.

**All users** are blocked if the LDAP server is unavailable when an LDAP user synchronization is run.

NOTE:
If all users are blocked due to the LDAP server not being available when an LDAP user synchronization is run,
a subsequent LDAP user synchronization does not automatically unblock those users.

## Group sync

If your LDAP supports the `memberof` property, when the user signs in for the
first time GitLab triggers a sync for groups the user should be a member of.
That way they don't have to wait for the hourly sync to be granted
access to their groups and projects.

A group sync process runs every hour on the hour, and `group_base` must be set
in LDAP configuration for LDAP synchronizations based on group CN to work. This allows
GitLab group membership to be automatically updated based on LDAP group members.

The `group_base` configuration should be a base LDAP 'container', such as an
'organization' or 'organizational unit', that contains LDAP groups that should
be available to GitLab. For example, `group_base` could be
`ou=groups,dc=example,dc=com`. In the configuration file, it looks like the
following.

NOTE:
If your LDAP server has a rate limit, that limit might be reached during the group sync process. Check the [rate limit documentation](#ldap-servers-with-rate-limits) for more information.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'group_base' => 'ou=groups,dc=example,dc=com',
       }
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             group_base: ou=groups,dc=example,dc=com
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'group_base' => 'ou=groups,dc=example,dc=com',
               }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           group_base: ou=groups,dc=example,dc=com
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

To take advantage of group sync, group Owners or users with the [Maintainer role](../../../user/permissions.md) must
[create one or more LDAP group links](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).

NOTE:
If you frequently experience connection issues between your LDAP server and GitLab instance, try reducing the frequency with which GitLab performs an LDAP group sync by
[setting the group sync worker interval](#adjust-ldap-group-sync-schedule) to be greater than the 1 hour default.

### Add group links

For information on adding group links by using CNs and filters, refer to the
[GitLab groups documentation](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).

### Administrator sync

As an extension of group sync, you can automatically manage your global GitLab
administrators. Specify a group CN for `admin_group` and all members of the
LDAP group are given administrator privileges. The configuration looks
like the following.

NOTE:
Administrators are not synced unless `group_base` is also
specified alongside `admin_group`. Also, only specify the CN of the `admin_group`,
as opposed to the full DN.
Additionally, if an LDAP user has an `admin` role, but is not a member of the `admin_group`
group, GitLab revokes their `admin` role when syncing.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'group_base' => 'ou=groups,dc=example,dc=com',
       'admin_group' => 'my_admin_group',
       }
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             group_base: ou=groups,dc=example,dc=com
             admin_group: my_admin_group
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'group_base' => 'ou=groups,dc=example,dc=com',
               'admin_group' => 'my_admin_group',
               }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           group_base: ou=groups,dc=example,dc=com
           admin_group: my_admin_group
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Global group memberships lock

GitLab administrators can prevent group members from inviting new members to subgroups that have their membership synchronized with LDAP.

Global group membership lock only applies to subgroups of the top-level group where LDAP synchronization is configured. No user can modify the
membership of a top-level group configured for LDAP synchronization.

When global group memberships lock is enabled:

- Only an administrator can manage memberships of any group including access levels.
- Users are not allowed to share a project with other groups or invite members to
  a project created in a group.

To enable global group memberships lock:

1. [Configure LDAP](_index.md#configure-ldap).
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Ensure the **Lock memberships to LDAP synchronization** checkbox is selected.

### Change LDAP group synchronization settings management

By default, group members with the Owner role can manage [LDAP group synchronization settings](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).

GitLab administrators can remove this permission from group Owners:

1. [Configure LDAP](_index.md#configure-ldap).
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Ensure the **Allow group owners to manage LDAP-related settings** checkbox is not checked.

When **Allow group owners to manage LDAP-related settings** is disabled:

- Group Owners cannot change LDAP synchronization settings for either top-level groups and subgroups.
- Instance administrators can manage LDAP group synchronization settings on all groups on an instance.

### External groups

Using the `external_groups` setting allows you to mark all users belonging
to these groups as [external users](../../external_users.md).
Group membership is checked periodically through the `LdapGroupSync` background
task.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'external_groups' => ['interns', 'contractors'],
       }
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             external_groups: ['interns', 'contractors']
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'external_groups' => ['interns', 'contractors'],
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           external_groups: ['interns', 'contractors']
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### GitLab Duo add-on for groups

The `duo_add_on_groups` setting automatically [manages Duo add-on seats](../../duo_add_on_seat_management_with_ldap.md) for users who authenticate through LDAP. This feature helps organizations to streamline their **GitLab Duo** seat allocation process based on LDAP group memberships.

To enable add-on seat management for groups, you must configure the `duo_add_on_groups` setting in your GitLab instance:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'duo_add_on_groups' => ['duo_group_1', 'duo_group_2'],
       }
   }
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
           duo_add_on_groups: => ['duo_group_1', 'duo_group_2'],
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
                 'duo_add_on_groups' => ['duo_group_1', 'duo_group_2'],
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           duo_add_on_groups: ['duo_group_1', 'duo_group_2']
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Group sync technical details

This section outlines what LDAP queries are executed and what behavior you
can expect from group sync.

Group member access are downgraded from a higher level if their LDAP group
membership changes. For example, if a user the Owner role in a group and the
next group sync reveals they should only have the Developer role, their
access is adjusted accordingly. The only exception is if the user is the
last owner in a group. Groups need at least one owner to fulfill
administrative duties.

#### Supported LDAP group types/attributes

GitLab supports LDAP groups that use member attributes:

- `member`
- `submember`
- `uniquemember`
- `memberof`
- `memberuid`

This means group sync supports (at least) LDAP groups with the following object
classes:

- `groupOfNames`
- `posixGroup`
- `groupOfUniqueNames`

Other object classes should work if members are defined as one of the
mentioned attributes.

Active Directory supports nested groups. Group sync recursively resolves
membership if `active_directory: true` is set in the configuration file.

##### Nested group memberships

Nested group memberships are resolved only if the nested group
is found in the configured `group_base`. For example, if GitLab sees a
nested group with DN `cn=nested_group,ou=special_groups,dc=example,dc=com` but
the configured `group_base` is `ou=groups,dc=example,dc=com`, `cn=nested_group`
is ignored.

#### Queries

- Each LDAP group is queried a maximum of one time with base `group_base` and
  filter `(cn=<cn_from_group_link>)`.
- If the LDAP group has the `memberuid` attribute, GitLab executes another
  LDAP query per member to obtain each user's full DN. These queries are
  executed with base `base`, scope 'base object', and a filter depending on
  whether `user_filter` is set. Filter may be `(uid=<uid_from_group>)` or a
  joining of `user_filter`.

#### Benchmarks

Group sync was written to be as performant as possible. Data is cached, database
queries are optimized, and LDAP queries are minimized. The last benchmark run
revealed the following metrics:

For 20,000 LDAP users, 11,000 LDAP groups, and 1,000 GitLab groups with 10
LDAP group links each:

- Initial sync (no existing members assigned in GitLab) took 1.8 hours
- Subsequent syncs (checking membership, no writes) took 15 minutes

These metrics are meant to provide a baseline and performance may vary based on
any number of factors. This benchmark was extreme and most instances don't
have near this many users or groups. Disk speed, database performance,
network and LDAP server response time affects these metrics.

### Adjust LDAP user sync schedule

By default, GitLab runs a worker once per day at 01:30 a.m. server time to
check and update GitLab users against LDAP.

WARNING:
Do not run the sync process too frequently as this could lead to multiple syncs running concurrently. Most installations do not need to modify the sync schedule. For more information, see the [LDAP Security documentation](_index.md#security).

You can manually configure LDAP user sync times by setting the
following configuration values, in cron format. If needed, you can
use a [crontab generator](http://www.crontabgenerator.com).
The example below shows how to set LDAP user
sync to run once every 12 hours at the top of the hour.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_sync_worker:
           cron: "0 */12 * * *"
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_sync_worker:
         cron: "0 */12 * * *"
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Adjust LDAP group sync schedule

By default, GitLab runs a group sync process every hour, on the hour.
The values shown are in cron format. If needed, you can use a
[Crontab Generator](http://www.crontabgenerator.com).

WARNING:
Do not start the sync process too frequently as this could lead to multiple syncs running concurrently. Most installations do not need to modify the sync schedule.

You can manually configure LDAP group sync times by setting the
following configuration values. The example below shows how to set group
sync to run once every two hours at the top of the hour.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * *"
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_group_sync_worker:
           cron: "*/30 * * * *"
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * *"
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_group_sync_worker:
         cron: "*/30 * * * *"
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Troubleshooting

See our [administrator guide to troubleshooting LDAP](ldap-troubleshooting.md).
