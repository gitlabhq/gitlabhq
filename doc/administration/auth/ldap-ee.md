---
type: reference
---

# LDAP Additions in GitLab EE **(STARTER ONLY)**

This section documents LDAP features specific to to GitLab Enterprise Edition
[Starter](https://about.gitlab.com/pricing/#self-managed) and above.

For documentation relevant to both Community Edition and Enterprise Edition,
see the main [LDAP documentation](ldap.md).

NOTE: **Note:**
[Microsoft Active Directory Trusts](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc771568(v=ws.10)) are not supported

## Use cases

- User sync: Once a day, GitLab will update users against LDAP.
- Group sync: Once an hour, GitLab will update group membership
  based on LDAP group members.

## Multiple LDAP servers

With GitLab Enterprise Edition Starter, you can configure multiple LDAP servers
that your GitLab instance will connect to.

To add another LDAP server:

1. Duplicating the settings under [the main configuration](ldap.md#configuration).
1. Edit them to match the additional LDAP server.

Be sure to choose a different provider ID made of letters a-z and numbers 0-9.
This ID will be stored in the database so that GitLab can remember which LDAP
server a user belongs to.

## User sync

Once per day, GitLab will run a worker to check and update GitLab
users against LDAP.

The process will execute the following access checks:

- Ensure the user is still present in LDAP.
- If the LDAP server is Active Directory, ensure the user is active (not
  blocked/disabled state). This will only be checked if
  `active_directory: true` is set in the LDAP configuration.

NOTE: **Note:**
In Active Directory, a user is marked as disabled/blocked if the user
account control attribute (`userAccountControl:1.2.840.113556.1.4.803`)
has bit 2 set. See <https://ctovswild.com/2009/09/03/bitmask-searches-in-ldap/>
for more information.

The user will be set to `ldap_blocked` state in GitLab if the above conditions
fail. This means the user will not be able to login or push/pull code.

The process will also update the following user information:

- Email address.
- If `sync_ssh_keys` is set, SSH public keys.
- If Kerberos is enabled, Kerberos identity.

NOTE: **Note:**
The LDAP sync process updates existing users while new users will
be created on first sign in.

## Group Sync

If your LDAP supports the `memberof` property, when the user signs in for the
first time GitLab will trigger a sync for groups the user should be a member of.
That way they don't need to wait for the hourly sync to be granted
access to their groups and projects.

A group sync process will run every hour on the hour, and `group_base` must be set
in LDAP configuration for LDAP synchronizations based on group CN to work. This allows
GitLab group membership to be automatically updated based on LDAP group members.

The `group_base` configuration should be a base LDAP 'container', such as an
'organization' or 'organizational unit', that contains LDAP groups that should
be available to GitLab. For example, `group_base` could be
`ou=groups,dc=example,dc=com`. In the config file it will look like the
following.

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = YAML.load <<-EOS
   main:
     ## snip...
     ##
     ## Base where we can search for groups
     ##
     ##   Ex. ou=groups,dc=gitlab,dc=example
     ##
     ##
     group_base: ou=groups,dc=example,dc=com
   EOS
   ```

1. [Apply your changes to GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

**Source configuration**

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           group_base: ou=groups,dc=example,dc=com
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

To take advantage of group sync, group owners or maintainers will need to [create one
or more LDAP group links](#adding-group-links).

### Adding group links

Once [group sync has been configured](#group-sync) on the instance, one or more LDAP
groups can be linked to a GitLab group to grant their members access to its
contents.

Group owners or maintainers can add and use LDAP group links by:

1. Navigating to the group's **Settings > LDAP Synchronization** page. Here, one or more
   LDAP groups and [filters](#filters-premium-only) can be linked to this GitLab group,
   each one with a configured [permission level](../../user/permissions.md#group-members-permissions)
   for its members.
1. Updating the group's membership by navigating to the group's **Settings > Members**
   page and clicking **Sync now**.

### Filters **(PREMIUM ONLY)**

In GitLab Premium, you can add an LDAP user filter for group synchronization.
Filters allow for complex logic without creating a special LDAP group.

To sync GitLab group membership based on an LDAP filter:

1. Open the **LDAP Synchronization** page for the GitLab group.
1. Select **LDAP user filter** as the **Sync method**.
1. Enter an LDAP user filter in the **LDAP user filter** field.

The filter must comply with the
syntax defined in [RFC 2254](https://tools.ietf.org/search/rfc2254).

## Administrator sync

As an extension of group sync, you can automatically manage your global GitLab
administrators. Specify a group CN for `admin_group` and all members of the
LDAP group will be given administrator privileges. The configuration will look
like the following.

NOTE: **Note:**
Administrators will not be synced unless `group_base` is also
specified alongside `admin_group`. Also, only specify the CN of the admin
group, as opposed to the full DN.

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = YAML.load <<-EOS
   main:
     ## snip...
     ##
     ## Base where we can search for groups
     ##
     ##   Ex. ou=groups,dc=gitlab,dc=example
     ##
     ##
     group_base: ou=groups,dc=example,dc=com

     ##
     ## The CN of a group containing GitLab administrators
     ##
     ##   Ex. administrators
     ##
     ##   Note: Not `cn=administrators` or the full DN
     ##
     ##
     admin_group: my_admin_group

   EOS
   ```

1. [Apply your changes to GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

**Source configuration**

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           group_base: ou=groups,dc=example,dc=com
           admin_group: my_admin_group
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Global group memberships lock

"Lock memberships to LDAP synchronization" setting allows instance administrators
to lock down user abilities to invite new members to a group.

When enabled, the following applies:

- Only administrator can manage memberships of any group including access levels.
- Users are not allowed to share project with other groups or invite members to
  a project created in a group.

## Adjusting LDAP user sync schedule

> Introduced in GitLab Enterprise Edition Starter.

NOTE: **Note:**
These are cron formatted values. You can use a crontab generator to create
these values, for example <http://www.crontabgenerator.com/>.

By default, GitLab will run a worker once per day at 01:30 a.m. server time to
check and update GitLab users against LDAP.

You can manually configure LDAP user sync times by setting the
following configuration values. The example below shows how to set LDAP user
sync to run once every 12 hours at the top of the hour.

**Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Source installations**

1. Edit `config/gitlab.yaml`:

   ```yaml
   cron_jobs:
     ldap_sync_worker_cron:
       "0 */12 * * *"
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Adjusting LDAP group sync schedule

NOTE: **Note:**
These are cron formatted values. You can use a crontab generator to create
these values, for example <http://www.crontabgenerator.com/>.

By default, GitLab will run a group sync process every hour, on the hour.

CAUTION: **Important:**
It's recommended that you do not run too short intervals as this
could lead to multiple syncs running concurrently. This is primarily a concern
for installations with a large number of LDAP users. Please review the
[LDAP group sync benchmark metrics](#benchmarks) to see how
your installation compares before proceeding.

You can manually configure LDAP group sync times by setting the
following configuration values. The example below shows how to set group
sync to run once every 2 hours at the top of the hour.

**Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * * *"
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**Source installations**

1. Edit `config/gitlab.yaml`:

   ```yaml
   cron_jobs:
     ldap_group_sync_worker_cron:
         "*/30 * * * *"
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

## External groups

> Introduced in GitLab Enterprise Edition Starter 8.9.

Using the `external_groups` setting will allow you to mark all users belonging
to these groups as [external users](../../user/permissions.md#external-users-core-only).
Group membership is checked periodically through the `LdapGroupSync` background
task.

**Omnibus configuration**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_servers'] = YAML.load <<-EOS
   main:
     ## snip...
     ##
     ## An array of CNs of groups containing users that should be considered external
     ##
     ##   Ex. ['interns', 'contractors']
     ##
     ##   Note: Not `cn=interns` or the full DN
     ##
     external_groups: ['interns', 'contractors']
   EOS
   ```

1. [Apply your changes to GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

**Source configuration**

1. Edit `config/gitlab.yaml`:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           external_groups: ['interns', 'contractors']
   ```

1. [Restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.

## Group sync technical details

There is a lot going on with group sync 'under the hood'. This section
outlines what LDAP queries are executed and what behavior you can expect
from group sync.

Group member access will be downgraded from a higher level if their LDAP group
membership changes. For example, if a user has 'Owner' rights in a group and the
next group sync reveals they should only have 'Developer' privileges, their
access will be adjusted accordingly. The only exception is if the user is the
*last* owner in a group. Groups need at least one owner to fulfill
administrative duties.

### Supported LDAP group types/attributes

GitLab supports LDAP groups that use member attributes:

- `member`
- `submember`
- `uniquemember`
- `memberof`
- `memberuid`.

This means group sync supports, at least, LDAP groups with object class:
`groupOfNames`, `posixGroup`, and `groupOfUniqueNames`.

Other object classes should work fine as long as members
are defined as one of the mentioned attributes. This also means GitLab supports
Microsoft Active Directory, Apple Open Directory, Open LDAP, and 389 Server.
Other LDAP servers should work, too.

Active Directory also supports nested groups. Group sync will recursively
resolve membership if `active_directory: true` is set in the configuration file.

NOTE: **Note:**
Nested group membership will only be resolved if the nested group
also falls within the configured `group_base`. For example, if GitLab sees a
nested group with DN `cn=nested_group,ou=special_groups,dc=example,dc=com` but
the configured `group_base` is `ou=groups,dc=example,dc=com`, `cn=nested_group`
will be ignored.

### Queries

- Each LDAP group is queried a maximum of one time with base `group_base` and
  filter `(cn=<cn_from_group_link>)`.
- If the LDAP group has the `memberuid` attribute, GitLab will execute another
  LDAP query per member to obtain each user's full DN. These queries are
  executed with base `base`, scope 'base object', and a filter depending on
  whether `user_filter` is set. Filter may be `(uid=<uid_from_group>)` or a
  joining of `user_filter`.

### Benchmarks

Group sync was written to be as performant as possible. Data is cached, database
queries are optimized, and LDAP queries are minimized. The last benchmark run
revealed the following metrics:

For 20000 LDAP users, 11000 LDAP groups and 1000 GitLab groups with 10
LDAP group links each:

- Initial sync (no existing members assigned in GitLab) took 1.8 hours
- Subsequent syncs (checking membership, no writes) took 15 minutes

These metrics are meant to provide a baseline and performance may vary based on
any number of factors. This was a pretty extreme benchmark and most instances will
not have near this many users or groups. Disk speed, database performance,
network and LDAP server response time will affect these metrics.

## Troubleshooting

Please see our [administrator guide to troubleshooting LDAP](ldap-troubleshooting.md).
