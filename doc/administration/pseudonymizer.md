# Pseudonymizer

## Object Storage Settings

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

    ```ruby
    gitlab_rails['pseudonymizer_enabled'] = true
    gitlab_rails['pseudonymizer_manifest'] = 'lib/pseudonymizer/manifest.yml'
    gitlab_rails['pseudonymizer_upload_remote_directory'] = 'gitlab-elt'
    gitlab_rails['pseudonymizer_upload_connection'] = {
      'provider' => 'AWS',
      'region' => 'eu-central-1',
      'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
      'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
    }
    ```

>**Note:**
If you are using AWS IAM profiles, be sure to omit the AWS access key and secret access key/value pairs.

    ```ruby
    gitlab_rails['pseudonymizer_upload_connection'] = {
      'provider' => 'AWS',
      'region' => 'eu-central-1',
      'use_iam_profile' => true
    }
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

    ```yaml
    pseudonymizer:
      enabled: true
	  manifest: lib/pseudonymizer/manifest.yml
	  upload:
        remote_directory: 'gitlab-elt' # The bucket name
        connection:
          provider: AWS # Only AWS supported at the moment
          aws_access_key_id: AWS_ACESS_KEY_ID
          aws_secret_access_key: AWS_SECRET_ACCESS_KEY
          region: eu-central-1
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.
