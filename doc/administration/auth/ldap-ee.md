# LDAP Additions in GitLab EE **[STARTER ONLY]**

This is a continuation of the main [LDAP documentation](ldap.md), detailing LDAP
features specific to GitLab Enterprise Edition.

## Overview

[LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)
stands for **Lightweight Directory Access Protocol**, which
is a standard application protocol for
accessing and maintaining distributed directory information services
over an Internet Protocol (IP) network.

GitLab integrates with LDAP to support **user authentication**. This integration
works with most LDAP-compliant directory servers, including Microsoft Active
Directory, Apple Open Directory, Open LDAP, and 389 Server.
**GitLab Enterprise Edition** includes enhanced integration, including group
membership syncing.

## Use-cases

- User Sync: Once a day, GitLab will update users against LDAP
- Group Sync: Once an hour, GitLab will update group membership
based on LDAP group members

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

## Group Sync **[PREMIUM ONLY]**

If your LDAP supports the `memberof` property, GitLab will add the user to any
new groups they might be added to when the user logs in. That way they don't need
to wait for the hourly sync to be granted access to the groups that they are in
in LDAP.

In GitLab Premium, we can also add a GitLab group to sync with one or multiple LDAP groups or we can
also add a filter. The filter must comply with the syntax defined in [RFC 2254](https://tools.ietf.org/search/rfc2254).

A group sync process will run every hour on the hour, and `group_base` must be set
in LDAP configuration for LDAP synchronizations based on group CN to work. This allows
GitLab group membership to be automatically updated based on LDAP group members.

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
groups and/or filters can be linked with a single GitLab group. When the link is
created, an access level/role is specified (Guest, Reporter, Developer, Master,
or Owner).

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


## External Groups

>**Note:** External Groups configuration is only available in GitLab EE Version
8.9 and above.

Using the `external_groups` setting will allow you to mark all users belonging
to these groups as [external users](../../user/permissions.md). Group membership is
checked periodically through the `LdapGroupSync` background task.

**Omnibus configuration**

```ruby
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
main:
  # snip...
  external_groups: ['interns', 'contractors']
EOS
```

[Reconfigure GitLab][reconfigure] for the changes to take effect.

**Source configuration**

```yaml
production:
  ldap:
    servers:
      main:
        # snip...
        external_groups: ['interns', 'contractors']
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

> **Note:** Nested group membership will only be resolved if the nested group
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

For 20,000 LDAP users, 11,000 LDAP groups and 1,000 GitLab groups with 10
LDAP group links each:

- Initial sync (no existing members assigned in GitLab) took 1.8 hours
- Subsequent syncs (checking membership, no writes) took 15 minutes

These metrics are meant to provide a baseline and performance may vary based on
any number of factors. This was a pretty extreme benchmark and most instances will
not have near this many users or groups. Disk speed, database performance,
network and LDAP server response time will affect these metrics.

## Troubleshooting

### Referral Error

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

### User DN has changed

When an LDAP user is created in GitLab, their LDAP DN is stored for later reference.

If GitLab cannot find a user by their DN, it will attempt to fallback
to finding the user by their email. If the lookup is successful, GitLab will
update the stored DN to the new value.

### User is not being added to a group

Sometimes you may think a particular user should be added to a GitLab group via
LDAP group sync, but for some reason it's not happening. There are several
things to check to debug the situation.

- Ensure LDAP configuration has a `group_base` specified. This configuration is
  required for group sync to work properly.
- Ensure the correct LDAP group link is added to the GitLab group. Check group
  links by visiting the GitLab group, then **Settings dropdown -> LDAP groups**.
- Check that the user has an LDAP identity
  1. Sign in to GitLab as an administrator user.
  1. Navigate to **Admin area -> Users**.
  1. Search for the user
  1. Open the user, by clicking on their name. Do not click 'Edit'.
  1. Navigate to the **Identities** tab. There should be an LDAP identity with
     an LDAP DN as the 'Identifier'.

If all of the above looks good, jump in to a little more advanced debugging.
Often, the best way to learn more about why group sync is behaving a certain
way is to enable debug logging. There is verbose output that details every
step of the sync.

1. Start a Rails console

    ```bash
    # For Omnibus installations
    sudo gitlab-rails console

    # For installations from source
    sudo -u git -H bundle exec rails console production
    ```
1. Set the log level to debug (only for this session):

    ```ruby
    Rails.logger.level = Logger::DEBUG
    ```
1. Choose a GitLab group to test with. This group should have an LDAP group link
   already configured. If the output is `nil`, the group could not be found.
   If a bunch of group attributes are output, your group was found successfully.

    ```ruby
    group = Group.find_by(name: 'my_group')

    # Output
    => #<Group:0x007fe825196558 id: 1234, name: "my_group"...>
    ```
1. Run a group sync for this particular group.

    ```ruby
    EE::Gitlab::Auth::LDAP::Sync::Group.execute_all_providers(group)
    ```
1. Look through the output of the sync. See [example log output](#example-log-output)
   below for more information about the output.
1. If you still aren't able to see why the user isn't being added, query the
   LDAP group directly to see what members are listed. Still in the Rails console,
   run the following query:

    ```ruby
    adapter = Gitlab::Auth::LDAP::Adapter.new('ldapmain') # If `main` is the LDAP provider
    ldap_group = EE::Gitlab::Auth::LDAP::Group.find_by_cn('group_cn_here', adapter)

    # Output
    => #<EE::Gitlab::Auth::LDAP::Group:0x007fcbdd0bb6d8
    ```
1. Query the LDAP group's member DNs and see if the user's DN is in the list.
   One of the DNs here should match the 'Identifier' from the LDAP identity
   checked earlier. If it doesn't, the user does not appear to be in the LDAP
   group.

    ```ruby
    ldap_group.member_dns

    # Output
    => ["uid=john,ou=people,dc=example,dc=com", "uid=mary,ou=people,dc=example,dc=com"]
    ```
1. Some LDAP servers don't store members by DN. Rather, they use UIDs instead.
   If you didn't see results from the last query, try querying by UIDs instead.

    ```ruby
    ldap_group.member_uids

    # Output
    => ['john','mary']
    ```

#### Example log output

The output of the last command will be very verbose, but contains lots of
helpful information. For the most part you can ignore log entries that are SQL
statements.

Indicates the point where syncing actually begins:

```bash
Started syncing all providers for 'my_group' group
```

The follow entry shows an array of all user DNs GitLab sees in the LDAP server.
Note that these are the users for a single LDAP group, not a GitLab group. If
you have multiple LDAP groups linked to this GitLab group, you will see multiple
log entries like this - one for each LDAP group. If you don't see an LDAP user
DN in this log entry, LDAP is not returning the user when we do the lookup.
Verify the user is actually in the LDAP group.

```bash
Members in 'ldap_group_1' LDAP group: ["uid=john0,ou=people,dc=example,dc=com",
"uid=mary0,ou=people,dc=example,dc=com", "uid=john1,ou=people,dc=example,dc=com",
"uid=mary1,ou=people,dc=example,dc=com", "uid=john2,ou=people,dc=example,dc=com",
"uid=mary2,ou=people,dc=example,dc=com", "uid=john3,ou=people,dc=example,dc=com",
"uid=mary3,ou=people,dc=example,dc=com", "uid=john4,ou=people,dc=example,dc=com",
"uid=mary4,ou=people,dc=example,dc=com"]
```

Shortly after each of the above entries, you will see a hash of resolved member
access levels. This hash represents all user DNs GitLab thinks should have
access to this group, and at which access level (role). This hash is additive,
and more DNs may be added, or existing entries modified, based on additional
LDAP group lookups. The very last occurrence of this entry should indicate
exactly which users GitLab believes should be added to the group.

> **Note:** 10 is 'Guest', 20 is 'Reporter', 30 is 'Developer', 40 is 'Master'
  and 50 is 'Owner'

```bash
Resolved 'my_group' group member access: {"uid=john0,ou=people,dc=example,dc=com"=>30,
"uid=mary0,ou=people,dc=example,dc=com"=>30, "uid=john1,ou=people,dc=example,dc=com"=>30,
"uid=mary1,ou=people,dc=example,dc=com"=>30, "uid=john2,ou=people,dc=example,dc=com"=>30,
"uid=mary2,ou=people,dc=example,dc=com"=>30, "uid=john3,ou=people,dc=example,dc=com"=>30,
"uid=mary3,ou=people,dc=example,dc=com"=>30, "uid=john4,ou=people,dc=example,dc=com"=>30,
"uid=mary4,ou=people,dc=example,dc=com"=>30}
```

It's not uncommon to see warnings like the following. These indicate that GitLab
would have added the user to a group, but the user could not be found in GitLab.
Usually this is not a cause for concern.

If you think a particular user should already exist in GitLab, but you're seeing
this entry, it could be due to a mismatched DN stored in GitLab. See
[User DN has changed](#User-DN-has-changed) to update the user's LDAP identity.

```bash
User with DN `uid=john0,ou=people,dc=example,dc=com` should have access
to 'my_group' group but there is no user in GitLab with that
identity. Membership will be updated once the user signs in for
the first time.
```

Finally, the following entry says syncing has finished for this group:

```bash
Finished syncing all providers for 'my_group' group
```
