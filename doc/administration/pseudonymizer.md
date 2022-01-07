---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pseudonymizer (DEPRECATED) **(ULTIMATE)**

> [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/219952) in GitLab 14.7.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/219952) in GitLab 14.7.

Your GitLab database contains sensitive information. To protect sensitive information
when you run analytics on your database, you can use the Pseudonymizer service, which:

1. Uses `HMAC(SHA256)` to mutate fields containing sensitive information.
1. Preserves references (referential integrity) between fields.
1. Exports your GitLab data, scrubbed of sensitive material.

WARNING:
If the source data is available, users can compare and correlate the scrubbed data
with the original.

To generate a pseudonymized data set:

1. [Configure Pseudonymizer](#configure-pseudonymizer) fields and output location.
1. [Enable Pseudonymizer data collection](#enable-pseudonymizer-data-collection).
1. Optional. [Generate a data set manually](#generate-data-set-manually).

## Configure Pseudonymizer

To use the Pseudonymizer, configure both the fields you want to anonymize, and the location to
store the scrubbed data:

1. **Create a manifest file**: This file describes the fields to include or pseudonymize.
   - **Default manifest** - GitLab provides a default manifest in your GitLab installation
     ([example `manifest.yml` file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/pseudonymizer.yml)).
     To use the example manifest file, use the `config/pseudonymizer.yml` relative path
     when you configure connection parameters.
   - **Custom manifest** - To use a custom manifest file, use the absolute path to
   the file when you configure the connection parameters.
1. **Configure connection parameters**: In the configuration method appropriate for
   your version of GitLab, specify the [object storage](object_storage.md)
   connection parameters (`pseudonymizer.upload.connection`).

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

   If you are using AWS IAM profiles, omit the AWS access key and secret access key/value pairs.

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

## Enable Pseudonymizer data collection

To enable data collection:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Settings > Metrics and Profiling**, then expand
   **Pseudonymizer data collection**.
1. Select **Enable Pseudonymizer data collection**.
1. Select **Save changes**.

## Generate data set manually

You can also run the Pseudonymizer manually:

1. Set these environment variables:
   - `PSEUDONYMIZER_OUTPUT_DIR` - Where to store the output CSV files. Defaults to `/tmp`.
     These commands produce CSV files that can be quite large. Make sure the directory
     can store a file at least 10% of the size of your database.
   - `PSEUDONYMIZER_BATCH` - The batch size when querying the database. Defaults to `100000`.
1. Run the command appropriate for your application:
   - **Omnibus GitLab**:
     `sudo gitlab-rake gitlab:db:pseudonymizer`
   - **Installations from source**:
     `sudo -u git -H bundle exec rake gitlab:db:pseudonymizer RAILS_ENV=production`

After you run the command, upload the output CSV files to your configured object
storage. After the upload completes, delete the output file from the local disk.

## Related topics

- [Using object storage with GitLab](object_storage.md).
