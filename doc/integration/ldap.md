# GitLab LDAP integration

GitLab can be configured to allow your users to sign with their LDAP credentials to integrate with e.g. Active Directory.
To enable LDAP integration, edit [gitlab.rb (omnibus-gitlab)`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#setting-up-ldap-sign-in) or [gitlab.yml (source installations)](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example) on your GitLab server and restart GitLab.

The first time a user signs in with LDAP credentials, GitLab will create a new GitLab user associated with the LDAP Distinguished Name (DN) of the LDAP user.

GitLab user attributes such as nickname and email will be copied from the LDAP user entry.

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
