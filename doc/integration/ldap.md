# GitLab LDAP integration

GitLab can be configured to allow your users to sign with their LDAP credentials to integrate with e.g. Active Directory.
To enable LDAP integration, edit [gitlab.rb (omnibus-gitlab)`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#setting-up-ldap-sign-in) or [gitlab.yml (source installations)](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example) on your GitLab server and restart GitLab.

The first time a user signs in with LDAP credentials, GitLab will create a new GitLab user associated with the LDAP Distinguished Name (DN) of the LDAP user.

GitLab user attributes such as nickname and email will be copied from the LDAP user entry.

## Configuring GitLab for LDAP integration

To enable GitLab LDAP integration you need to add your LDAP server settings in `/etc/gitlab/gitlab.rb` or `/home/git/gitlab/config/gitlab.yml`.
In GitLab Enterprise Edition you can have multiple LDAP servers connected to one GitLab server.

Please note that before version 7.4, GitLab used a different syntax for configuring LDAP integration.
The old LDAP integration syntax still works in GitLab 7.4.
If your `gitlab.rb` or `gitlab.yml` file contains LDAP settings in both the old syntax and the new syntax, only the __old__ syntax will be used by GitLab.

```ruby
# For omnibus packages
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = YAML.load <<-EOS # remember to close this block with 'EOS' below
main: # 'main' is the GitLab 'provider ID' of this LDAP server
  ## label
  #
  # A human-friendly name for your LDAP server. It is OK to change the label later,
  # for instance if you find out it is too large to fit on the web page.
  #
  # Example: 'Paris' or 'Acme, Ltd.'
  label: 'LDAP'

  host: '_your_ldap_server'
  port: 389
  uid: 'sAMAccountName'
  method: 'plain' # "tls" or "ssl" or "plain"
  bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
  password: '_the_password_of_the_bind_user'

  # This setting specifies if LDAP server is Active Directory LDAP server.
  # For non AD servers it skips the AD specific queries.
  # If your LDAP server is not AD, set this to false.
  active_directory: true

  # If allow_username_or_email_login is enabled, GitLab will ignore everything
  # after the first '@' in the LDAP username submitted by the user on login.
  #
  # Example:
  # - the user enters 'jane.doe@example.com' and 'p@ssw0rd' as LDAP credentials;
  # - GitLab queries the LDAP server with 'jane.doe' and 'p@ssw0rd'.
  #
  # If you are using "uid: 'userPrincipalName'" on ActiveDirectory you need to
  # disable this setting, because the userPrincipalName contains an '@'.
  allow_username_or_email_login: false

  # Base where we can search for users
  #
  #   Ex. ou=People,dc=gitlab,dc=example
  #
  base: ''

  # Filter LDAP users
  #
  #   Format: RFC 4515 http://tools.ietf.org/search/rfc4515
  #   Ex. (employeeType=developer)
  #
  #   Note: GitLab does not support omniauth-ldap's custom filter syntax.
  #
  user_filter: ''

# GitLab EE only: add more LDAP servers
# Choose an ID made of a-z and 0-9 . This ID will be stored in the database
# so that GitLab can remember which LDAP server a user belongs to.
# uswest2:
#   label:
#   host:
#   ....
EOS
```

If you are getting 'Connection Refused' errors when trying to connect to the LDAP server please double-check the LDAP `port` and `method` settings used by GitLab.
Common combinations are `method: 'plain'` and `port: 389`, OR `method: 'ssl'` and `port: 636`.

If you are using a GitLab installation from source you can find the LDAP settings in `/home/git/gitlab/config/gitlab.yml`:

```
production:
  # snip...
  ldap:
    enabled: false
    servers:
      main: # 'main' is the GitLab 'provider ID' of this LDAP server
        ## label
        #
        # A human-friendly name for your LDAP server. It is OK to change the label later,
        # for instance if you find out it is too large to fit on the web page.
        #
        # Example: 'Paris' or 'Acme, Ltd.'
        label: 'LDAP'
        # snip...
```

## Enabling LDAP sign-in for existing GitLab users

When a user signs in to GitLab with LDAP for the first time, and their LDAP email address is the primary email address of an existing GitLab user, then the LDAP DN will be associated with the existing user.

If the LDAP email attribute is not found in GitLab's database, a new user is created.

In other words, if an existing GitLab user wants to enable LDAP sign-in for themselves, they should check that their GitLab email address matches their LDAP email address, and then sign into GitLab via their LDAP credentials.

GitLab recognizes the following LDAP attributes as email addresses: `mail`, `email` and `userPrincipalName`.

If multiple LDAP email attributes are present, e.g. `mail: foo@bar.com` and `email: foo@example.com`, then the first attribute found wins -- in this case `foo@bar.com`.

## LDAP group synchronization (GitLab Enterprise Edition)

LDAP group synchronization in GitLab Enterprise Edition allows you to synchronize the members of a GitLab group with one or more LDAP groups.

### Setting up LDAP group synchronization

Suppose we want to synchronize the GitLab group 'example group' with the LDAP group 'Engineering'.

1. As an owner, go to the group settings page for 'example group'.

![LDAP group settings](ldap/select_group_cn.png)

As an admin you can also go to the group edit page in the admin area.

![LDAP group settings for admins](ldap/select_group_cn_admin.png)

2. Enter 'Engineering' as the LDAP Common Name (CN) in the 'LDAP Group cn' field.

3. Enter a default group access level in the 'LDAP Access' field; let's say Developer.

![LDAP group settings filled in](ldap/select_group_cn_engineering.png)

4. Click 'Add synchronization' to add the new LDAP group link.

Now every time a member of the 'Engineering' LDAP group signs in, they automatically become a Developer-level member of the 'example group' GitLab group. Users who are already signed in will see the change in membership after up to one hour.

### Synchronizing with more than one LDAP group (GitLab EE 7.3 and newer)

If you want to add the members of LDAP group to your GitLab group you can add an additional LDAP group link.
If you have two LDAP group links, e.g. 'cn=Engineering' at level 'Developer' and 'cn=QA' at level 'Reporter', and user Jane belongs to both the 'Engineering' and 'QA' LDAP groups, she will get the _highest_ access level of the two, namely 'Developer'.

![Two linked LDAP groups](ldap/two_linked_ldap_groups.png)

### Locking yourself out of your own group

As an LDAP-enabled GitLab user, if you create a group and then set it to synchronize with an LDAP group you do not belong to, you will be removed from the grop as soon as the synchronization takes effect for you.

If you accidentally lock yourself out of your own GitLab group, ask a GitLab administrator to change the LDAP synchronization settings for your group.

### Non-LDAP GitLab users

Your GitLab instance may have users on it for whom LDAP is not enabled.
If this is the case, these users will not be affected by LDAP group synchronization settings: they will be neither added nor removed automatically.

### ActiveDirectory nested group support

If you are using ActiveDirectory, it is possible to create nested LDAP groups: the 'Engineering' LDAP group may contain another LDAP group 'Software', with 'Software' containing LDAP users Alice and Bob.
GitLab will recognize Alice and Bob as members of the 'Engineering' group.

## Define GitLab admin status via LDAP

It is possible to configure GitLab Enterprise Edition (7.1 and newer) so that GitLab admin rights are bestowed on the members of a given LDAP group.
GitLab administrator users who do not have LDAP enabled are not affected by the LDAP admin group feature.

### Enabling the admin group feature

Below we assume that you have an LDAP group with the common name (CN) 'GitLab administrators' containing the users that should be GitLab administrators.
We recommend that you keep a non-LDAP GitLab administrator user around on your GitLab instance in case you accidentally remove the admin status from your own LDAP-enabled GitLab user.

For omnibus-gitlab, add the following to `/etc/gitlab/gitlab.rb` and run `gitlab-ctl reconfigure`.

```ruby
gitlab_rails['ldap_admin_group'] = 'GitLab administrators'
```

For installations from source, add the following setting in the 'ldap' section of gitlab.yml, and run `service gitlab reload` afterwards.

```yaml
    admin_group: 'Gitlab administrators'
```

## Synchronising user SSH keys with LDAP

It is possible to configure GitLab Enterprise Edition (7.1 and newer) so that users have their SSH public keys synchronised with an attribute in their LDAP object.
Existing SSH public keys that are manually manged in GitLab are not affected by this feature.

### Enabling the key synchronisation feature

Below we assume that you have LDAP users with an attribute  'sshpublickey' containing the users ssh public key.

For omnibus-gitlab, add the following to `/etc/gitlab/gitlab.rb` and run `gitlab-ctl reconfigure`.

```ruby
gitlab_rails['ldap_sync_ssh_keys'] = 'sshpublickey'
```

For installations from source, add the following setting in the 'ldap' section of gitlab.yml, and run `service gitlab reload` afterwards.

```yaml
    sync_ssh_keys: 'sshpublickey'
```

## Using an LDAP filter to limit access to your GitLab server

If you want to limit all GitLab access to a subset of the LDAP users on your LDAP server you can set up an LDAP user filter.
The filter must comply with [RFC 4515](http://tools.ietf.org/search/rfc4515).

```ruby
# For omnibus packages; new LDAP server syntax
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
main:
  # snip...
  user_filter: '(employeeType=developer)'
EOS
```

```yaml
# For installations from source; new LDAP server syntax
production:
  ldap:
    servers:
      main:
        # snip...
        user_filter: '(employeeType=developer)'
```

Tip: if you want to limit access to the nested members of an Active Directory group you can use the following syntax:

```
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

Please note that GitLab does not support the custom filter syntax used by omniauth-ldap.

## Integrate GitLab with more than one LDAP server (Enterprise Edition)

Starting with GitLab Enterprise Edition 7.4 it is possible to give users from more than one LDAP server access to the same GitLab server.

Please use the following steps to enable support for multiple LDAP servers.

### 1. Check your GitLab version

Go to gitlab.example.com/help and verify you are running GitLab Enterprise Edition 7.4.0 or newer.

### 2. Make sure your GitLab server uses the new LDAP syntax

```
# For omnibus packages
sudo gitlab-rails runner 'puts (Gitlab.config.ldap["host"] ? :old_syntax : :new_syntax)'

# For installations from source
cd /home/git/gitlab
bundle exec rails runner -e production 'puts (Gitlab.config.ldap["host"] ? :old_syntax : :new_syntax)'
```

### 3. Migrate existing users and groups

After switching to the new LDAP configuration syntax there will be a mismatch between the LDAP provider linked to your GitLab users and groups and the new LDAP provider defined in GitLab's configuration.
The following command will associate all existing legacy LDAP users and groups on your GitLab server with the first LDAP server listed in `gitlab.rb` (omnibus) or `gitlab.yml`.

```
# For omnibus packages
sudo gitlab-rake gitlab:migrate_ldap_providers

# For installations from source
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:migrate_ldap_providers RAILS_ENV=production
```

### 4. Add new LDAP servers

Now you can add new LDAP servers via `/etc/gitlab/gitlab.rb` (omnibus packages) or `gitlab.yml` (installations from source).
Remember to run `sudo gitlab-ctl reconfigure` or `sudo service gitlab reload` for the new servers to become available.

## Automatic Daily LDAP Sync

GitLab Enterprise Edition will now automatically sync all LDAP members on a daily basis. You can configure the time that it happens.

LDAP group synchronization in GitLab Enterprise Edition works by GitLab periodically updating the group memberships of _active_ GitLab users.
If a GitLab user becomes _inactive_ however, their group memberships in GitLab can start to lag behind the LDAP server group memberships.
Starting with GitLab 7.5 Enterprise Edition, GitLab will also update the LDAP group memberships of inactive users, by doing a daily LDAP check for _all_ GitLab users.

> Example:
John Doe leaves the company and is removed from the LDAP server.
At this point he can no longer log in to GitLab 7.4 EE.
But because he is no longer active on the GitLab EE server (he cannot log in!), his LDAP group memberships in GitLab no longer get updated, and he stays listed as a group member on the GitLab server.

> Now with GitLab 7.5 Enterprise Edition, within 24 hours of John being removed from the LDAP server, his user will also stop being listed as member of any GitLab groups.

## LDAP Synchronization

LDAP membership is checked for a GitLab user:

- when they sign in to the GitLab instance
- on a daily basis
- on any request that they do, once the LDAP cache has expired (default 1 hour, configurable, cache is per user)

If you want a shorter or longer LDAP sync time, you can easily set this with the `sync_time` attribute in your config.

For Omnibus package installations, simply add `"sync_time"` in `/etc/gitlab/gitlab.rb` to your LDAP config.
A typical LDAP configuration for GitLab installed with an Omnibus package might look like this:

```
gitlab_rails['ldap_servers'] = YAML.load <<-EOS
main:
  label: 'LDAP'
  host: '_your_ldap_server'
  port: 636
  uid: 'sAMAccountName'
  method: 'ssl' # "tls" or "ssl" or "plain"
  bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
  password: '_the_password_of_the_bind_user'
  active_directory: true
  allow_username_or_email_login: false
  base: ''
  user_filter: ''
  sync_time: 1800
  ## EE only
  group_base: ''
  admin_group: ''
  sync_ssh_keys: false
EOS
```

Here, `sync_time` is set to `1800` seconds, meaning the LDAP cache will expire every 30 minutes.

For manual GitLab installations, simply uncomment the `sync_time` entry in your `gitlab.yml` and set it to the value you desire.

Please note that changing the LDAP sync time can influence the performance of your GitLab instance.
