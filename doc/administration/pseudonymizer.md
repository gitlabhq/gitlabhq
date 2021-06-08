---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pseudonymizer **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/5532) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.1.

As the GitLab database hosts sensitive information, using it unfiltered for analytics
implies high security requirements. To help alleviate this constraint, the Pseudonymizer
service is used to export GitLab data in a pseudonymized way.

WARNING:
This process is not impervious. If the source data is available, it's possible for
a user to correlate data to the pseudonymized version.

The Pseudonymizer currently uses `HMAC(SHA256)` to mutate fields that shouldn't
be textually exported. This ensures that:

- the end-user of the data source cannot infer/revert the pseudonymized fields
- the referential integrity is maintained

## Configuration

To configure the Pseudonymizer, you need to:

- Provide a manifest file that describes which fields should be included or
  pseudonymized ([example `manifest.yml` file](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/pseudonymizer.yml)).
  A default manifest is provided with the GitLab installation, using a relative file path that resolves from the Rails root.
  Alternatively, you can use an absolute file path.
- Use an object storage and specify the connection parameters in the `pseudonymizer.upload.connection` configuration option.

[Read more about using object storage with GitLab](object_storage.md).

**For Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

   ```ruby
   gitlab_rails['pseudonymizer_manifest'] = 'config/pseudonymizer.yml'
   gitlab_rails['pseudonymizer_upload_remote_directory'] = 'gitlab-elt' # bucket name
   gitlab_rails['pseudonymizer_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   If you are using AWS IAM profiles, be sure to omit the AWS access key and secret access key/value pairs.

   ```ruby
   gitlab_rails['pseudonymizer_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

---

**For installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   pseudonymizer:
     manifest: config/pseudonymizer.yml
     upload:
       remote_directory: 'gitlab-elt' # bucket name
       connection:
         provider: AWS
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source)
   for the changes to take effect.

## Usage

You can optionally run the Pseudonymizer using the following environment variables:

- `PSEUDONYMIZER_OUTPUT_DIR` - where to store the output CSV files (defaults to `/tmp`)
- `PSEUDONYMIZER_BATCH` - the batch size when querying the DB (defaults to `100000`)

```shell
## Omnibus
sudo gitlab-rake gitlab:db:pseudonymizer

## Source
sudo -u git -H bundle exec rake gitlab:db:pseudonymizer RAILS_ENV=production
```

This produces some CSV files that might be very large, so make sure the
`PSEUDONYMIZER_OUTPUT_DIR` has sufficient space. As a rule of thumb, at least
10% of the database size is recommended.

After the pseudonymizer has run, the output CSV files should be uploaded to the
configured object storage and deleted from the local disk.
