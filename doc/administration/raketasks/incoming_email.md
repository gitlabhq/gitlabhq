---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Incoming email Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279) in GitLab 15.9.

The following are Incoming email-related Rake tasks.

## Secrets

GitLab can use [Incoming email](../incoming_email.md) secrets read from an encrypted file instead of storing them in plaintext in the file system. The following Rake tasks are provided for updating the contents of the encrypted file.

### Show secret

Show the contents of the current Incoming email secrets.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-rake gitlab:incoming_email:secret:show
```

:::TabTitle Helm chart (Kubernetes)

Use a Kubernetes secret to store the incoming email password. For more information,
read about [Helm IMAP secrets](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-incoming-emails).

:::TabTitle Docker

```shell
sudo docker exec -t <container name> gitlab:incoming_email:secret:show
```

:::TabTitle Self-compiled (source)

```shell
bundle exec rake gitlab:incoming_email:secret:show RAILS_ENV=production
```

::EndTabs

#### Example output

```plaintext
password: 'examplepassword'
user: 'incoming-email@mail.example.com'
```

### Edit secret

Opens the secret contents in your editor, and writes the resulting content to the encrypted secret file when you exit.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-rake gitlab:incoming_email:secret:edit EDITOR=vim
```

:::TabTitle Helm chart (Kubernetes)

Use a Kubernetes secret to store the incoming email password. For more information,
read about [Helm IMAP secrets](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-incoming-emails).

:::TabTitle Docker

```shell
sudo docker exec -t <container name> gitlab:incoming_email:secret:edit EDITOR=editor
```

:::TabTitle Self-compiled (source)

```shell
bundle exec rake gitlab:incoming_email:secret:edit RAILS_ENV=production EDITOR=vim
```

::EndTabs

### Write raw secret

Write new secret content by providing it on `STDIN`.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
echo -e "password: 'examplepassword'" | sudo gitlab-rake gitlab:incoming_email:secret:write
```

:::TabTitle Helm chart (Kubernetes)

Use a Kubernetes secret to store the incoming email password. For more information,
read about [Helm IMAP secrets](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-incoming-emails).

:::TabTitle Docker

```shell
sudo docker exec -t <container name> /bin/bash
echo -e "password: 'examplepassword'" | gitlab-rake gitlab:incoming_email:secret:write
```

:::TabTitle Self-compiled (source)

```shell
echo -e "password: 'examplepassword'" | bundle exec rake gitlab:incoming_email:secret:write RAILS_ENV=production
```

::EndTabs

### Secrets examples

**Editor example**

The write task can be used in cases where the edit command does not work with your editor:

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:incoming_email:secret:show > incoming_email.yaml
# Edit the incoming_email file in your editor
...
# Re-encrypt the file
cat incoming_email.yaml | sudo gitlab-rake gitlab:incoming_email:secret:write
# Remove the plaintext file
rm incoming_email.yaml
```

**KMS integration example**

It can also be used as a receiving application for content encrypted with a KMS:

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:incoming_email:secret:write
```

**Google Cloud secret integration example**

It can also be used as a receiving application for secrets out of Google Cloud:

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:incoming_email:secret:write
```
