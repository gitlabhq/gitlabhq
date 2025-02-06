---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SMTP Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The following are SMTP-related Rake tasks.

## Secrets

GitLab can use SMTP configuration secrets to read from an encrypted file. The following Rake tasks are provided for updating the contents of the encrypted file.

### Show secret

Show the contents of the current SMTP secrets.

- Linux package installations:

  ```shell
  sudo gitlab-rake gitlab:smtp:secret:show
  ```

- Self-compiled installations:

  ```shell
  bundle exec rake gitlab:smtp:secret:show RAILS_ENV=production
  ```

**Example output:**

```plaintext
password: '123'
user_name: 'gitlab-inst'
```

### Edit secret

Opens the secret contents in your editor, and writes the resulting content to the encrypted secret file when you exit.

- Linux package installations:

  ```shell
  sudo gitlab-rake gitlab:smtp:secret:edit EDITOR=vim
  ```

- Self-compiled installations:

  ```shell
  bundle exec rake gitlab:smtp:secret:edit RAILS_ENV=production EDITOR=vim
  ```

### Write raw secret

Write new secret content by providing it on `STDIN`.

- Linux package installations:

  ```shell
  echo -e "password: '123'" | sudo gitlab-rake gitlab:smtp:secret:write
  ```

- Self-compiled installations:

  ```shell
  echo -e "password: '123'" | bundle exec rake gitlab:smtp:secret:write RAILS_ENV=production
  ```

### Secrets examples

**Editor example**

The write task can be used in cases where the edit command does not work with your editor:

```shell
# Write the existing secret to a plaintext file
sudo gitlab-rake gitlab:smtp:secret:show > smtp.yaml
# Edit the smtp file in your editor
...
# Re-encrypt the file
cat smtp.yaml | sudo gitlab-rake gitlab:smtp:secret:write
# Remove the plaintext file
rm smtp.yaml
```

**KMS integration example**

It can also be used as a receiving application for content encrypted with a KMS:

```shell
gcloud kms decrypt --key my-key --keyring my-test-kms --plaintext-file=- --ciphertext-file=my-file --location=us-west1 | sudo gitlab-rake gitlab:smtp:secret:write
```

**Google Cloud secret integration example**

It can also be used as a receiving application for secrets out of Google Cloud:

```shell
gcloud secrets versions access latest --secret="my-test-secret" > $1 | sudo gitlab-rake gitlab:smtp:secret:write
```
