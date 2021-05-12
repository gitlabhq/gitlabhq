---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# LDAP Rake tasks **(FREE SELF)**

The following are LDAP-related Rake tasks.

## Check

The LDAP check Rake task tests the `bind_dn` and `password` credentials
(if configured) and lists a sample of LDAP users. This task is also
executed as part of the `gitlab:check` task, but can run independently
using the command below.

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:ldap:check
```

**Source Installation**

```shell
sudo -u git -H bundle exec rake gitlab:ldap:check RAILS_ENV=production
```

By default, the task returns a sample of 100 LDAP users. Change this
limit by passing a number to the check task:

```shell
rake gitlab:ldap:check[50]
```

## Run a group sync **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/14735) in GitLab 12.2.

The following task runs a [group sync](../auth/ldap/index.md#group-sync) immediately. This is valuable
when you'd like to update all configured group memberships against LDAP without
waiting for the next scheduled group sync to be run.

NOTE:
If you'd like to change the frequency at which a group sync is performed,
[adjust the cron schedule](../auth/ldap/index.md#adjusting-ldap-group-sync-schedule)
instead.

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:ldap:group_sync
```

**Source Installation**

```shell
bundle exec rake gitlab:ldap:group_sync
```

## Rename a provider

If you change the LDAP server ID in `gitlab.yml` or `gitlab.rb` you need
to update all user identities or users aren't able to sign in. Input the
old and new provider and this task updates all matching identities in the
database.

`old_provider` and `new_provider` are derived from the prefix `ldap` plus the
LDAP server ID from the configuration file. For example, in `gitlab.yml` or
`gitlab.rb` you may see LDAP configuration like this:

```yaml
main:
  label: 'LDAP'
  host: '_your_ldap_server'
  port: 389
  uid: 'sAMAccountName'
  ...
```

`main` is the LDAP server ID. Together, the unique provider is `ldapmain`.

WARNING:
If you input an incorrect new provider, users cannot sign in. If this happens,
run the task again with the incorrect provider as the `old_provider` and the
correct provider as the `new_provider`.

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

**Source Installation**

```shell
bundle exec rake gitlab:ldap:rename_provider[old_provider,new_provider] RAILS_ENV=production
```

### Example

Consider beginning with the default server ID `main` (full provider `ldapmain`).
If we change `main` to `mycompany`, the `new_provider` is `ldapmycompany`.
To rename all user identities run the following command:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[ldapmain,ldapmycompany]
```

Example output:

```plaintext
100 users with provider 'ldapmain' will be updated to 'ldapmycompany'.
If the new provider is incorrect, users will be unable to sign in.
Do you want to continue (yes/no)? yes

User identities were successfully updated
```

### Other options

If you do not specify an `old_provider` and `new_provider` the task prompts you
for them:

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:ldap:rename_provider
```

**Source Installation**

```shell
bundle exec rake gitlab:ldap:rename_provider RAILS_ENV=production
```

**Example output:**

```plaintext
What is the old provider? Ex. 'ldapmain': ldapmain
What is the new provider? Ex. 'ldapcustom': ldapmycompany
```

This task also accepts the `force` environment variable, which skips the
confirmation dialog:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider] force=yes
```

## Secrets

GitLab can use [LDAP configuration secrets](../auth/ldap/index.md#using-encrypted-credentials) to read from an encrypted file. The following Rake tasks are provided for updating the contents of the encrypted file.

### Show secret

Show the contents of the current LDAP secrets.

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:ldap:secret:show
```

**Source Installation**

```shell
bundle exec rake gitlab:ldap:secret:show RAILS_ENV=production
```

**Example output:**

```plaintext
main:
  password: '123'
  user_bn: 'gitlab-adm'
```

### Edit secret

Opens the secret contents in your editor, and writes the resulting content to the encrypted secret file when you exit.

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
```

**Source Installation**

```shell
bundle exec rake gitlab:ldap:secret:edit RAILS_ENV=production EDITOR=vim
```

### Write raw secret

Write new secret content by providing it on STDIN.

**Omnibus Installation**

```shell
echo -e "main:\n  password: '123'" | sudo gitlab-rake gitlab:ldap:secret:write
```

**Source Installation**

```shell
echo -e "main:\n  password: '123'" | bundle exec rake gitlab:ldap:secret:write RAILS_ENV=production
```

### Secrets examples

**Editor example**

The write task can be used in cases where the edit command does not work with your editor:

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:ldap:secret:show > ldap.yaml
# Edit the ldap file in your editor
...
# Re-encrypt the file
cat ldap.yaml | sudo gitlab-rake gitlab:ldap:secret:write
# Remove the plaintext file
rm ldap.yaml
```

**KMS integration example**

It can also be used as a receiving application for content encrypted with a KMS:

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:ldap:secret:write
```

**Google Cloud secret integration example**

It can also be used as a receiving application for secrets out of Google Cloud:

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:ldap:secret:write
```
