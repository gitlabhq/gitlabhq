---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: LDAP Rake tasks
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The following are LDAP-related Rake tasks.

## Check

The LDAP check Rake task tests the `bind_dn` and `password` credentials
(if configured) and lists a sample of LDAP users. This task is also
executed as part of the `gitlab:check` task, but can run independently
using the command below.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:check
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:check
```

{{< /tab >}}

{{< /tabs >}}

By default, the task returns a sample of 100 LDAP users. Change this
limit by passing a number to the check task:

```shell
rake gitlab:ldap:check[50]
```

## Run a group sync

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The following task runs a [group sync](../auth/ldap/ldap_synchronization.md#group-sync) immediately.
This is valuable when you'd like to update all configured group memberships against LDAP without
waiting for the next scheduled group sync to be run.

{{< alert type="note" >}}

If you'd like to change the frequency at which a group sync is performed,
[adjust the cron schedule](../auth/ldap/ldap_synchronization.md#adjust-ldap-group-sync-schedule)
instead.

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:group_sync
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:group_sync
```

{{< /tab >}}

{{< /tabs >}}

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
  # ...
```

`main` is the LDAP server ID. Together, the unique provider is `ldapmain`.

{{< alert type="warning" >}}

If you input an incorrect new provider, users cannot sign in. If this happens,
run the task again with the incorrect provider as the `old_provider` and the
correct provider as the `new_provider`.

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:rename_provider[old_provider,new_provider]
```

{{< /tab >}}

{{< /tabs >}}

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

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:rename_provider
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:rename_provider
```

{{< /tab >}}

{{< /tabs >}}

**Example output**:

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

GitLab can use [LDAP configuration secrets](../auth/ldap/_index.md#use-encrypted-credentials) to read from an encrypted file.
The following Rake tasks are provided for updating the contents of the encrypted file.

### Show secret

Show the contents of the current LDAP secrets.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:secret:show
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:secret:show
```

{{< /tab >}}

{{< /tabs >}}

**Example output**:

```plaintext
main:
  password: '123'
  bind_dn: 'gitlab-adm'
```

### Edit secret

Opens the secret contents in your editor, and writes the resulting content to the encrypted secret file when you exit.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
sudo RAILS_ENV=production EDITOR=vim -u git -H bundle exec rake gitlab:ldap:secret:edit
```

{{< /tab >}}

{{< /tabs >}}

### Write raw secret

Write new secret content by providing it on STDIN.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
echo -e "main:\n  password: '123'" | sudo gitlab-rake gitlab:ldap:secret:write
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
echo -e "main:\n  password: '123'" | sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:ldap:secret:write
```

{{< /tab >}}

{{< /tabs >}}

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
