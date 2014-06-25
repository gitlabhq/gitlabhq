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

LDAP group synchronization in GitLab Enterprise Edition allows you to synchronize the members of a GitLab group with a given LDAP group.

### Setting up LDAP group synchronization

Suppose we want to synchronize the GitLab group 'example group' with the LDAP group 'Engineering'.

1. As an owner, go to the group settings page for 'example group'.

![LDAP group settings](ldap/select_group_cn.png)

As an admin you can also go to the group edit page in the admin area.

![LDAP group settings for admins](ldap/select_group_cn_admin.png)

2. Enter 'Engineering' as the LDAP Common Name (CN) in the 'LDAP Group cn' field.

3. Enter a default group access level in the 'LDAP Access' field; let's say Developer.

![LDAP group settings filled in](ldap/select_group_cn_engineering.png)

4. Save your changes to the group settings.

Now every time a member of the 'Engineering' LDAP group signs in, they automatically become a Developer-level member of the 'example group' GitLab group. Users who are already signed in will see the change in membership after up to one hour.

### Locking yourself out of your own group

As an LDAP-enabled GitLab user, if you create a group and then set it to synchronize with an LDAP group you do not belong to, you will be removed from the grop as soon as the synchronization takes effect for you.

If you accidentally lock yourself out of your own GitLab group, ask a GitLab administrator to change the LDAP synchronization settings for your group.

### Non-LDAP GitLab users

Your GitLab instance may have users on it for whom LDAP is not enabled.
If this is the case, these users will not be affected by LDAP group synchronization settings: they will be neither added nor removed automatically.

### ActiveDirectory nested group support

If you are using ActiveDirectory, it is possible to create nested LDAP groups: the 'Engineering' LDAP group may contain another LDAP group 'Software', with 'Software' containing LDAP users Alice and Bob.
GitLab will recognize Alice and Bob as members of the 'Engineering' group.
