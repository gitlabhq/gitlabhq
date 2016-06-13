# LDAP Additions in GitLab EE

This is a continuation of the main [LDAP documentation](ldap.md), detailing LDAP
features specific to GitLab Enterprise Edition.

## User Sync

Once per day, GitLab will run a worker to check and update GitLab
users against LDAP.

The process will execute the following access checks:

1. Ensure the user is still present in LDAP
1. If the LDAP server is Active Directory, ensure the user is active (not
   blocked/disabled state). This will only be checked if
   `active_directory: true` is set in the LDAP configuration [^1]

The user will be set to `ldap_blocked` state in GitLab if the above conditions
fail. This means the user will not be able to login or push/pull code.

The process will also update the following user information:

1. Email address
1. If `sync_ssh_keys` is set, SSH public keys
1. If Kerberos is enabled, Kerberos identity

> **Note:** The LDAP sync process updates existing users while new users will
  be created on first sign in.

## Group Sync

If `group_base` is set in LDAP configuration, a group sync process will run
every hour, on the hour. This allows GitLab group membership to be automatically
updated based on LDAP group members.

The `group_base` configuration should be a base LDAP 'container', such as an
'organization' or 'organizational unit', that contains LDAP groups that should
be available to GitLab. For example, `group_base` could be
`ou=groups,dc=example,dc=com`. In the config file it will look like the
following.

**Omnibus configuration**

Edit `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
main:
  # snip...
  group_base: ou=groups,dc=example,dc=com
EOS
```

[Reconfigure GitLab][reconfigure] for the changes to take effect.

**Source configuration**

Edit `/home/git/gitlab/config/gitlab.yml`:

```yaml
production:
  ldap:
    servers:
      main:
        # snip...
        group_base: ou=groups,dc=example,dc=com
```

[Restart GitLab][restart] for the changes to take effect.

---

To take advantage of group sync, group owners or masters will need to create an
LDAP group link in their group **Settings -> LDAP Groups** page. Multiple LDAP
groups can be linked with a single GitLab group. When the link is created, an
access level/role is specified (Guest, Reporter, Developer, Master, or Owner).

## Administrator Sync

As an extension of group sync, you can automatically manage your global GitLab
administrators. Specify a group CN for `admin_group` and all members of the
LDAP group will be given administrator privileges. The configuration will look
like the following.

> **Note:** Administrators will not be synced unless `group_base` is also
  specified alongside `admin_group`. Also, only specify the CN of the admin
  group, as opposed to the full DN.

**Omnibus configuration**

Edit `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
main:
  # snip...
  group_base: ou=groups,dc=example,dc=com
  admin_group: my_admin_group
EOS
```

[Reconfigure GitLab][reconfigure] for the changes to take effect.

**Source configuration**

Edit `/home/git/gitlab/config/gitlab.yml`:

```yaml
production:
  ldap:
    servers:
      main:
        # snip...
        group_base: ou=groups,dc=example,dc=com
        admin_group: my_admin_group
```

[Restart GitLab][restart] for the changes to take effect.

## Group Sync Technical Details

There is a lot going on with group sync 'under the hood'. This section
outlines what LDAP queries are executed and what behavior you can expect
from group sync.

Group member access will be downgraded from a higher level if their LDAP group
membership changes. For example, if a user has 'Owner' rights in a group and the
next group sync reveals they should only have 'Developer' privileges, their
access will be adjusted accordingly. The only exception is if the user is the
*last* owner in a group. Groups need at least one owner to fulfill
administrative duties.

### Supported LDAP Group Types/Attributes

GitLab supports LDAP groups that use member attributes `member`, `submember`,
`uniquemember`, `memberof` and `memberuid`. This means group sync supports, at
least, LDAP groups with object class `groupOfNames`, `posixGroup`, and
`groupOfUniqueName`. Other object classes should work fine as long as members
are defined as one of the mentioned attributes. This also means GitLab supports
Microsoft Active Directory, Apple Open Directory, Open LDAP, and 389 Server.
Other LDAP servers should work, too.

Active Directory also supports nested groups. Group sync will recursively
resolve membership if `active_directory: true` is set in the configuration file.

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

For 20,000 LDAP users, 11,000 LDAP groups and 1,000 GitLab groups with 10
LDAP group links each:

- Initial sync (no existing members assigned in GitLab) took 1.8 hours
- Subsequent syncs (checking membership, no writes) took 15 minutes

These metrics are meant to provide a baseline and performance may vary based on
any number of factors. This was a pretty extreme benchmark and most instances will
not have near this many users or groups. Disk speed, database performance,
network and LDAP server response time will affect these metrics.

## Troubleshooting

If you see `LDAP search error: Referral` in the logs, or when troubleshooting
LDAP Group Sync, this error may indicate a configuration problem. The LDAP
configuration `/etc/gitlab/gitlab.rb` (Omnibus) or `config/gitlab.yml` (source)
is in YAML format and is sensitive to indentation. Check that `group_base` and
`admin_group` configuration keys are indented 2 spaces past the server
identifier. The default identifier is `main` and an example snippet looks like
the following:

```yaml
main: # 'main' is the GitLab 'provider ID' of this LDAP server
  label: 'LDAP'
  host: 'ldap.example.com'
  ...
  group_base: 'cn=my_group,ou=groups,dc=example,dc=com'
  admin_group: 'my_admin_group'
```

[reconfigure]: ../restart_gitlab.md#omnibus-gitlab-reconfigure
[restart]: ../restart_gitlab.md#installations-from-source

[^1]: In Active Directory, a user is marked as disabled/blocked if the user
      account control attribute (`userAccountControl:1.2.840.113556.1.4.803`)
      has bit 2 set. See https://ctogonewild.com/2009/09/03/bitmask-searches-in-ldap/
      for more information.
