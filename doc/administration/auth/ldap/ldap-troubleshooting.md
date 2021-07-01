---
type: reference
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# LDAP Troubleshooting for Administrators **(FREE SELF)**

## Common Problems & Workflows

### Connection

#### Connection refused

If you're getting `Connection Refused` error messages when attempting to
connect to the LDAP server, review the LDAP `port` and `encryption` settings
used by GitLab. Common combinations are `encryption: 'plain'` and `port: 389`,
or `encryption: 'simple_tls'` and `port: 636`.

#### Connection times out

If GitLab cannot reach your LDAP endpoint, you see a message like this:

```plaintext
Could not authenticate you from Ldapmain because "Connection timed out - user specified timeout".
```

If your configured LDAP provider and/or endpoint is offline or otherwise
unreachable by GitLab, no LDAP user is able to authenticate and sign-in.
GitLab does not cache or store credentials for LDAP users to provide authentication
during an LDAP outage.

Contact your LDAP provider or administrator if you are seeing this error.

#### Referral error

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

#### Query LDAP **(PREMIUM SELF)**

The following allows you to perform a search in LDAP using the rails console.
Depending on what you're trying to do, it may make more sense to query [a
user](#query-a-user-in-ldap) or [a group](#query-a-group-in-ldap) directly, or
even [use `ldapsearch`](#ldapsearch) instead.

```ruby
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain')
options = {
    # :base is required
    # use .base or .group_base
    base: adapter.config.group_base,

    # :filter is optional
    # 'cn' looks for all "cn"s under :base
    # '*' is the search string - here, it's a wildcard
    filter: Net::LDAP::Filter.eq('cn', '*'),

    # :attributes is optional
    # the attributes we want to get returnedk
    attributes: %w(dn cn memberuid member submember uniquemember memberof)
}
adapter.ldap_search(options)
```

For examples of how this is run,
[review the `Adapter` module](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/auth/ldap/adapter.rb).

### User sign-ins

#### No users are found

If [you've confirmed](#ldap-check) that a connection to LDAP can be
established but GitLab doesn't show you LDAP users in the output, one of the
following is most likely true:

- The `bind_dn` user doesn't have enough permissions to traverse the user tree.
- The user(s) don't fall under the [configured `base`](index.md#configuration).
- The [configured `user_filter`](index.md#set-up-ldap-user-filter) blocks access to the user(s).

In this case, you con confirm which of the above is true using
[ldapsearch](#ldapsearch) with the existing LDAP configuration in your
`/etc/gitlab/gitlab.rb`.

#### User(s) cannot sign-in

A user can have trouble signing in for any number of reasons. To get started,
here are some questions to ask yourself:

- Does the user fall under the [configured `base`](index.md#configuration) in
  LDAP? The user must fall under this `base` to sign in.
- Does the user pass through the [configured `user_filter`](index.md#set-up-ldap-user-filter)?
  If one is not configured, this question can be ignored. If it is, then the
  user must also pass through this filter to be allowed to sign in.
  - Refer to our docs on [debugging the `user_filter`](#debug-ldap-user-filter).

If the above are both okay, the next place to look for the problem is
the logs themselves while reproducing the issue.

- Ask the user to sign in and let it fail.
- [Look through the output](#gitlab-logs) for any errors or other
  messages about the sign-in. You may see one of the other error messages on
  this page, in which case that section can help resolve the issue.

If the logs don't lead to the root of the problem, use the
[rails console](#rails-console) to [query this user](#query-a-user-in-ldap)
to see if GitLab can read this user on the LDAP server.

It can also be helpful to
[debug a user sync](#sync-all-users) to
investigate further.

#### Invalid credentials on sign-in

If that the sign-in credentials used are accurate on LDAP, ensure the following
are true for the user in question:

- Make sure the user you are binding with has enough permissions to read the user's
  tree and traverse it.
- Check that the `user_filter` is not blocking otherwise valid users.
- Run [an LDAP check command](#ldap-check) to make sure that the LDAP settings
  are correct and [GitLab can see your users](#no-users-are-found).

#### Access denied for your LDAP account

There is [a bug](https://gitlab.com/gitlab-org/gitlab/-/issues/235930) that
may affect users with [Auditor level access](../../auditor_users.md). When
downgrading from Premium/Ultimate, Auditor users who try to sign in
may see the following message: `Access denied for your LDAP account`.

We have a workaround, based on toggling the access level of affected users:

1. As an administrator, on the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the name of the affected user.
1. In the user's administrative page, press **Edit** on the top right of the page.
1. Change the user's access level from `Regular` to `Admin` (or vice versa),
   and press **Save changes** at the bottom of the page.
1. Press **Edit** on the top right of the user's profile page
   again.
1. Restore the user's original access level (`Regular` or `Admin`)
   and press **Save changes** again.

The user should now be able to sign in.

#### Email has already been taken

A user tries to sign in with the correct LDAP credentials, is denied access,
and the [production.log](../../logs.md#productionlog) shows an error that looks like this:

```plaintext
(LDAP) Error saving user <USER DN> (email@example.com): ["Email has already been taken"]
```

This error is referring to the email address in LDAP, `email@example.com`. Email
addresses must be unique in GitLab and LDAP links to a user's primary email (as opposed
to any of their possibly-numerous secondary emails). Another user (or even the
same user) has the email `email@example.com` set as a secondary email, which
is throwing this error.

We can check where this conflicting email address is coming from using the
[rails console](#rails-console). Once in the console, run the following:

```ruby
# This searches for an email among the primary AND secondary emails
user = User.find_by_any_email('email@example.com')
user.username
```

This shows you which user has this email address. One of two steps must be taken here:

- To create a new GitLab user/username for this user when signing in with LDAP,
  remove the secondary email to remove the conflict.
- To use an existing GitLab user/username for this user to use with LDAP,
  remove this email as a secondary email and make it a primary one so GitLab
  associates this profile to the LDAP identity.

The user can do either of these steps [in their
profile](../../../user/profile/index.md#access-your-user-profile) or an administrator can do it.

#### Projects limit errors

The following errors indicate that a limit or restriction is activated, but an associated data
field contains no data:

- `Projects limit can't be blank`.
- `Projects limit is not a number`.

To resolve this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, go to **Settings > General**.
1. Expand both of the following:
   - **Account and limit**.
   - **Sign-up restrictions**.
1. Check, for example, the **Default projects limit** or **Allowed domains for sign-ups**
   fields and ensure that a relevant value is configured.

#### Debug LDAP user filter

[`ldapsearch`](#ldapsearch) allows you to test your configured
[user filter](index.md#set-up-ldap-user-filter)
to confirm that it returns the users you expect it to return.

```shell
ldapsearch -H ldaps://$host:$port -D "$bind_dn" -y bind_dn_password.txt  -b "$base" "$user_filter" sAMAccountName
```

- Variables beginning with a `$` refer to a variable from the LDAP section of
  your configuration file.
- Replace `ldaps://` with `ldap://` if you are using the plain authentication method.
  Port `389` is the default `ldap://` port and `636` is the default `ldaps://`
  port.
- We are assuming the password for the `bind_dn` user is in `bind_dn_password.txt`.

#### Sync all users **(PREMIUM SELF)**

The output from a manual [user sync](index.md#user-sync) can show you what happens when
GitLab tries to sync its users against LDAP. Enter the [rails console](#rails-console)
and then run:

```ruby
Rails.logger.level = Logger::DEBUG

LdapSyncWorker.new.perform
```

Next, [learn how to read the
output](#example-console-output-after-a-user-sync).

##### Example console output after a user sync **(PREMIUM SELF)**

The output from a [manual user sync](#sync-all-users) is very verbose, and a
single user's successful sync can look like this:

```shell
Syncing user John, email@example.com
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
Instantiating Gitlab::Auth::Ldap::Person with LDIF:
dn: cn=John Smith,ou=people,dc=example,dc=com
cn: John Smith
mail: email@example.com
memberof: cn=admin_staff,ou=people,dc=example,dc=com
uid: John

  UserSyncedAttributesMetadata Load (0.9ms)  SELECT  "user_synced_attributes_metadata".* FROM "user_synced_attributes_metadata" WHERE "user_synced_attributes_metadata"."user_id" = 20 LIMIT 1
   (0.3ms)  BEGIN
  Namespace Load (1.0ms)  SELECT  "namespaces".* FROM "namespaces" WHERE "namespaces"."owner_id" = 20 AND "namespaces"."type" IS NULL LIMIT 1
  Route Load (0.8ms)  SELECT  "routes".* FROM "routes" WHERE "routes"."source_id" = 27 AND "routes"."source_type" = 'Namespace' LIMIT 1
  Ci::Runner Load (1.1ms)  SELECT "ci_runners".* FROM "ci_runners" INNER JOIN "ci_runner_namespaces" ON "ci_runners"."id" = "ci_runner_namespaces"."runner_id" WHERE "ci_runner_namespaces"."namespace_id" = 27
   (0.7ms)  COMMIT
   (0.4ms)  BEGIN
  Route Load (0.8ms)  SELECT "routes".* FROM "routes" WHERE (LOWER("routes"."path") = LOWER('John'))
  Namespace Load (1.0ms)  SELECT  "namespaces".* FROM "namespaces" WHERE "namespaces"."id" = 27 LIMIT 1
  Route Exists (0.9ms)  SELECT  1 AS one FROM "routes" WHERE LOWER("routes"."path") = LOWER('John') AND "routes"."id" != 50 LIMIT 1
  User Update (1.1ms)  UPDATE "users" SET "updated_at" = '2019-10-17 14:40:59.751685', "last_credential_check_at" = '2019-10-17 14:40:59.738714' WHERE "users"."id" = 20
```

There's a lot here, so let's go over what could be helpful when debugging.

First, GitLab looks for all users that have previously
signed in with LDAP and iterate on them. Each user's sync starts with
the following line that contains the user's username and email, as they
exist in GitLab now:

```shell
Syncing user John, email@example.com
```

If you don't find a particular user's GitLab email in the output, then that
user hasn't signed in with LDAP yet.

Next, GitLab searches its `identities` table for the existing
link between this user and the configured LDAP provider(s):

```sql
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
```

The identity object has the DN that GitLab uses to look for the user
in LDAP. If the DN isn't found, the email is used instead. We can see that
this user is found in LDAP:

```shell
Instantiating Gitlab::Auth::Ldap::Person with LDIF:
dn: cn=John Smith,ou=people,dc=example,dc=com
cn: John Smith
mail: email@example.com
memberof: cn=admin_staff,ou=people,dc=example,dc=com
uid: John
```

If the user wasn't found in LDAP with either the DN or email, you may see the
following message instead:

```shell
LDAP search error: No Such Object
```

...in which case the user is blocked:

```shell
  User Update (0.4ms)  UPDATE "users" SET "state" = $1, "updated_at" = $2 WHERE "users"."id" = $3  [["state", "ldap_blocked"], ["updated_at", "2019-10-18 15:46:22.902177"], ["id", 20]]
```

Once the user is found in LDAP, the rest of the output updates the GitLab
database with any changes.

#### Query a user in LDAP

This tests that GitLab can reach out to LDAP and read a particular user.
It can expose potential errors connecting to and/or querying LDAP
that may seem to fail silently in the GitLab UI.

```ruby
Rails.logger.level = Logger::DEBUG

adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
Gitlab::Auth::Ldap::Person.find_by_uid('<uid>', adapter)
```

### Group memberships **(PREMIUM SELF)**

#### Membership(s) not granted **(PREMIUM SELF)**

Sometimes you may think a particular user should be added to a GitLab group via
LDAP group sync, but for some reason it's not happening. There are several
things to check to debug the situation.

- Ensure LDAP configuration has a `group_base` specified.
  [This configuration](index.md#group-sync) is required for group sync to work properly.
- Ensure the correct [LDAP group link is added to the GitLab
  group](index.md#adding-group-links).
- Check that the user has an LDAP identity:
  1. Sign in to GitLab as an administrator user.
  1. On the top bar, select **Menu >** **{admin}** **Admin**.
  1. On the left sidebar, select **Overview > Users**.
  1. Search for the user.
  1. Open the user by clicking their name. Do not click **Edit**.
  1. Select the **Identities** tab. There should be an LDAP identity with
     an LDAP DN as the 'Identifier'. If not, this user hasn't signed in with
     LDAP yet and must do so first.
- You've waited an hour or [the configured
  interval](index.md#adjusting-ldap-group-sync-schedule) for the group to
  sync. To speed up the process, either go to the GitLab group **Group information > Members**
  and press **Sync now** (sync one group) or [run the group sync Rake
  task](../../raketasks/ldap.md#run-a-group-sync) (sync all groups).

If all of the above looks good, jump in to a little more advanced debugging in
the rails console.

1. Enter the [rails console](#rails-console).
1. Choose a GitLab group to test with. This group should have an LDAP group link
   already configured.
1. [Enable debug logging, find the above GitLab group, and sync it with LDAP](#sync-one-group).
1. Look through the output of the sync. See [example log
   output](#example-console-output-after-a-group-sync)
   for how to read the output.
1. If you still aren't able to see why the user isn't being added, [query the
   LDAP group directly](#query-a-group-in-ldap) to see what members are listed.
1. Is the user's DN or UID in one of the lists from the above output? One of the DNs or
   UIDs here should match the 'Identifier' from the LDAP identity checked earlier. If it doesn't,
   the user does not appear to be in the LDAP group.

#### Administrator privileges not granted

When [Administrator sync](index.md#administrator-sync) has been configured
but the configured users aren't granted the correct administrator privileges, confirm
the following are true:

- A [`group_base` is also configured](index.md#group-sync).
- The configured `admin_group` in the `gitlab.rb` is a CN, rather than a DN or an array.
- This CN falls under the scope of the configured `group_base`.
- The members of the `admin_group` have already signed into GitLab with their LDAP
  credentials. GitLab only grants this administrator access to the users whose
  accounts are already connected to LDAP.

If all the above are true and the users are still not getting access, [run a manual
group sync](#sync-all-groups) in the rails console and [look through the
output](#example-console-output-after-a-group-sync) to see what happens when
GitLab syncs the `admin_group`.

#### Sync all groups **(PREMIUM SELF)**

NOTE:
To sync all groups manually when debugging is unnecessary, [use the Rake
task](../../raketasks/ldap.md#run-a-group-sync) instead.

The output from a manual [group sync](index.md#group-sync) can show you what happens
when GitLab syncs its LDAP group memberships against LDAP.

```ruby
Rails.logger.level = Logger::DEBUG

LdapAllGroupsSyncWorker.new.perform
```

Next, [learn how to read the
output](#example-console-output-after-a-group-sync).

##### Example console output after a group sync **(PREMIUM SELF)**

Like the output from the user sync, the output from the [manual group
sync](#sync-all-groups) is also very verbose. However, it contains lots
of helpful information.

Indicates the point where syncing actually begins:

```shell
Started syncing 'ldapmain' provider for 'my_group' group
```

The following entry shows an array of all user DNs GitLab sees in the LDAP server.
Note that these are the users for a single LDAP group, not a GitLab group. If
you have multiple LDAP groups linked to this GitLab group, you see multiple
log entries like this - one for each LDAP group. If you don't see an LDAP user
DN in this log entry, LDAP is not returning the user when we do the lookup.
Verify the user is actually in the LDAP group.

```shell
Members in 'ldap_group_1' LDAP group: ["uid=john0,ou=people,dc=example,dc=com",
"uid=mary0,ou=people,dc=example,dc=com", "uid=john1,ou=people,dc=example,dc=com",
"uid=mary1,ou=people,dc=example,dc=com", "uid=john2,ou=people,dc=example,dc=com",
"uid=mary2,ou=people,dc=example,dc=com", "uid=john3,ou=people,dc=example,dc=com",
"uid=mary3,ou=people,dc=example,dc=com", "uid=john4,ou=people,dc=example,dc=com",
"uid=mary4,ou=people,dc=example,dc=com"]
```

Shortly after each of the above entries, you see a hash of resolved member
access levels. This hash represents all user DNs GitLab thinks should have
access to this group, and at which access level (role). This hash is additive,
and more DNs may be added, or existing entries modified, based on additional
LDAP group lookups. The very last occurrence of this entry should indicate
exactly which users GitLab believes should be added to the group.

NOTE:
10 is 'Guest', 20 is 'Reporter', 30 is 'Developer', 40 is 'Maintainer'
and 50 is 'Owner'.

```shell
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
[User DN and/or email have changed](#user-dn-orand-email-have-changed) to update the user's LDAP identity.

```shell
User with DN `uid=john0,ou=people,dc=example,dc=com` should have access
to 'my_group' group but there is no user in GitLab with that
identity. Membership will be updated once the user signs in for
the first time.
```

Finally, the following entry says syncing has finished for this group:

```shell
Finished syncing all providers for 'my_group' group
```

Once all the configured group links have been synchronized, GitLab looks
for any Administrators or External users to sync:

```shell
Syncing admin users for 'ldapmain' provider
```

The output looks similar to what happens with a single group, and then
this line indicates the sync is finished:

```shell
Finished syncing admin users for 'ldapmain' provider
```

If [administrator sync](index.md#administrator-sync) is not configured, you see a message
stating as such:

```shell
No `admin_group` configured for 'ldapmain' provider. Skipping
```

#### Sync one group **(PREMIUM SELF)**

[Syncing all groups](#sync-all-groups) can produce a lot of noise in the output, which can be
distracting when you're only interested in troubleshooting the memberships of
a single GitLab group. In that case, here's how you can just sync this group
and see its debug output:

```ruby
Rails.logger.level = Logger::DEBUG

# Find the GitLab group.
# If the output is `nil`, the group could not be found.
# If a bunch of group attributes are in the output, your group was found successfully.
group = Group.find_by(name: 'my_gitlab_group')

# Sync this group against LDAP
EE::Gitlab::Auth::Ldap::Sync::Group.execute_all_providers(group)
```

The output is similar to
[that you get from syncing all groups](#example-console-output-after-a-group-sync).

#### Query a group in LDAP **(PREMIUM SELF)**

When you'd like to confirm that GitLab can read a LDAP group and see all its members,
you can run the following:

```ruby
# Find the adapter and the group itself
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
ldap_group = EE::Gitlab::Auth::Ldap::Group.find_by_cn('group_cn_here', adapter)

# Find the members of the LDAP group
ldap_group.member_dns
ldap_group.member_uids
```

### User DN or/and email have changed

When an LDAP user is created in GitLab, their LDAP DN is stored for later reference.

If GitLab cannot find a user by their DN, it falls back
to finding the user by their email. If the lookup is successful, GitLab
updates the stored DN to the new value so both values now match what's in
LDAP.

If the email has changed and the DN has not, GitLab finds the user with
the DN and update its own record of the user's email to match the one in LDAP.

However, if the primary email _and_ the DN change in LDAP, then GitLab
has no way of identifying the correct LDAP record of the user and, as a
result, the user is blocked. To rectify this, the user's existing
profile must be updated with at least one of the new values (primary
email or DN) so the LDAP record can be found.

The following script updates the emails for all provided users so they
aren't blocked or unable to access their accounts.

NOTE:
The following script requires that any new accounts with the new
email address are removed first. This is because emails have to be unique in GitLab.

Go to the [rails console](#rails-console) and then run:

```ruby
# Each entry will have to include the old username and the new email
emails = {
  'ORIGINAL_USERNAME' => 'NEW_EMAIL_ADDRESS',
  ...
}

emails.each do |username, email|
  user = User.find_by_username(username)
  user.email = email
  user.skip_reconfirmation!
  user.save!
end
```

You can then [run a UserSync](#sync-all-users) **(PREMIUM SELF)** to sync the latest DN
for each of these users.

## Debugging Tools

### LDAP check

The [Rake task to check LDAP](../../raketasks/ldap.md#check) is a valuable tool
to help determine whether GitLab can successfully establish a connection to
LDAP and can get so far as to even read users.

If a connection can't be established, it is likely either because of a problem
with your configuration or a firewall blocking the connection.

- Ensure you don't have a firewall blocking the
connection, and that the LDAP server is accessible to the GitLab host.
- Look for an error message in the Rake check output, which may lead to your LDAP configuration to
confirm that the configuration values (specifically `host`, `port`, `bind_dn`, and
`password`) are correct.
- Look for [errors](#connection) in [the logs](#gitlab-logs) to further debug connection failures.

If GitLab can successfully connect to LDAP but doesn't return any
users, [see what to do when no users are found](#no-users-are-found).

### GitLab logs

If a user account is blocked or unblocked due to the LDAP configuration, a
message is [logged to `application.log`](../../logs.md#applicationlog).

If there is an unexpected error during an LDAP lookup (configuration error,
timeout), the sign-in is rejected and a message is [logged to
`production.log`](../../logs.md#productionlog).

### ldapsearch

`ldapsearch` is a utility that allows you to query your LDAP server. You can
use it to test your LDAP settings and ensure that the settings you're using
get you the results you expect.

When using `ldapsearch`, be sure to use the same settings you've already
specified in your `gitlab.rb` configuration so you can confirm what happens
when those exact settings are used.

Running this command on the GitLab host also helps confirm that there's no
obstruction between the GitLab host and LDAP.

For example, consider the following GitLab configuration:

```shell
gitlab_rails['ldap_servers'] = YAML.load <<-'EOS' # remember to close this block with 'EOS' below
   main: # 'main' is the GitLab 'provider ID' of this LDAP server
     label: 'LDAP'
     host: '127.0.0.1'
     port: 389
     uid: 'uid'
     encryption: 'plain'
     bind_dn: 'cn=admin,dc=ldap-testing,dc=example,dc=com'
     password: 'Password1'
     active_directory: true
     allow_username_or_email_login: false
     block_auto_created_users: false
     base: 'dc=ldap-testing,dc=example,dc=com'
     user_filter: ''
     attributes:
       username: ['uid', 'userid', 'sAMAccountName']
       email:    ['mail', 'email', 'userPrincipalName']
       name:       'cn'
       first_name: 'givenName'
       last_name:  'sn'
     group_base: 'ou=groups,dc=ldap-testing,dc=example,dc=com'
     admin_group: 'gitlab_admin'
EOS
```

You would run the following `ldapsearch` to find the `bind_dn` user:

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h 127.0.0.1 \
  -b "dc=ldap-testing,dc=example,dc=com"
```

Note that the `bind_dn`, `password`, `port`, `host`, and `base` are all
identical to what's configured in the `gitlab.rb`.

For more information, see the [official `ldapsearch` documentation](https://linux.die.net/man/1/ldapsearch).

### Using **AdFind** (Windows)

You can use the [`AdFind`](https://social.technet.microsoft.com/wiki/contents/articles/7535.adfind-command-examples.aspx) utility (on Windows based systems) to test that your LDAP server is accessible and authentication is working correctly. This is a freeware utility built by [Joe Richards](http://www.joeware.net/freetools/tools/adfind/index.htm).

**Return all objects**

You can use the filter `objectclass=*` to return all directory objects.

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f (objectClass=*)
```

**Return single object using filter**

You can also retrieve a single object by **specifying** the object name or full **DN**. In this example we specify the object name only `CN=Leroy Fox`.

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f "(&(objectcategory=person)(CN=Leroy Fox))"
```

### Rails console

WARNING:
It is very easy to create, read, modify, and destroy data with the rails
console. Be sure to run commands exactly as listed.

The rails console is a valuable tool to help debug LDAP problems. It allows you to
directly interact with the application by running commands and seeing how GitLab
responds to them.

For instructions about how to use the rails console, refer to this
[guide](../../operations/rails_console.md#starting-a-rails-console-session).

#### Enable debug output

This provides debug output that is useful to see
what GitLab is doing and with what. This value is not persisted, and is only
enabled for this session in the rails console.

To enable debug output in the rails console, [enter the rails
console](#rails-console) and run:

```ruby
Rails.logger.level = Logger::DEBUG
```
