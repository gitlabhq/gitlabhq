# Uploads administration

>**Notes:**
Uploads represent all user data that may be sent to GitLab as a single file. As an example, avatars and notes' attachments are uploads. Uploads are integral to GitLab functionality, and therefore cannot be disabled.

### Using local storage

>**Notes:**
This is the default configuration

To change the location where the uploads are stored locally, follow the steps
below.

---

**In Omnibus installations:**

>**Notes:**
For historical reasons, uploads are stored into a base directory, which by default is `uploads/-/system`. It is strongly discouraged to change this configuration option on an existing GitLab installation.

_The uploads are stored by default in `/var/opt/gitlab/gitlab-rails/public/uploads/-/system`._

1. To change the storage path for example to `/mnt/storage/uploads`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['uploads_storage_path'] = "/mnt/storage/"
	gitlab_rails['uploads_base_dir'] = "uploads"
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

_The uploads are stored by default in
`/home/git/gitlab/public/uploads/-/system`._

1. To change the storage path for example to `/mnt/storage/uploads`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

    ```yaml
	uploads:
	  storage_path: /mnt/storage
	  base_dir: uploads
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.

### Using object storage

>**Notes:**
- [Introduced][ee-3867] in [GitLab Enterprise Edition Premium][eep] 10.5.

If you don't want to use the local disk where GitLab is installed to store the
uploads, you can use an object storage provider like AWS S3 instead.
This configuration relies on valid AWS credentials to be configured already.

**In Omnibus installations:**

_The uploads are stored by default in
`/var/opt/gitlab/gitlab-rails/public/uploads/-/system`._

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

    ```ruby
    gitlab_rails['uploads_object_store_enabled'] = true
    gitlab_rails['uploads_object_store_remote_directory'] = "uploads"
    gitlab_rails['uploads_object_store_connection'] = {
      'provider' => 'AWS',
      'region' => 'eu-central-1',
      'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
      'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
    }
    ```

>**Note:**
If you are using AWS IAM profiles, be sure to omit the AWS access key and secret acces key/value pairs.

    ```ruby
    gitlab_rails['uploads_object_store_connection'] = {
      'provider' => 'AWS',
      'region' => 'eu-central-1',
      'use_iam_profile' => true
    }
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.
1. Migrate any existing local uploads to the object storage:

>**Notes:**
These task complies with the `BATCH` environment variable to process uploads in batch (200 by default). All of the processing will be done in a background worker and requires **no downtime**.

      ```bash
      # gitlab-rake gitlab:uploads:migrate[uploader_class, model_class, mount_point]
	  
	  # Avatars
	  gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
	  gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
	  gitlab-rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

      # Attachments
	  gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Note, :attachment]"
	  gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
	  gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

      # Markdown
	  gitlab-rake "gitlab:uploads:migrate[FileUploader, Project]"
	  gitlab-rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
	  gitlab-rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
	  gitlab-rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"
      ```

      Currently this has to be executed manually and it will allow you to
      migrate the existing uploads to the object storage, but all new
      uploads will still be stored on the local disk. In the future
      you will be given an option to define a default storage for all
      new files.

---

**In installations from source:**

_The uploads are stored by default in
`/home/git/gitlab/public/uploads/-/system`._

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

    ```yaml
    uploads:
      object_store:
        enabled: true
        remote_directory: "uploads" # The bucket name
        connection:
          provider: AWS # Only AWS supported at the moment
          aws_access_key_id: AWS_ACESS_KEY_ID
          aws_secret_access_key: AWS_SECRET_ACCESS_KEY
          region: eu-central-1
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.
1. Migrate any existing local uploads to the object storage:

>**Notes:**

- These task comply with the `BATCH` environment variable to process uploads in batch (200 by default). All of the processing will be done in a background worker and requires **no downtime**.

- To migrate in production use `RAILS_ENV=production` environment variable.

      ```bash
      # sudo -u git -H bundle exec rake gitlab:uploads:migrate
	  
	  # Avatars
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

      # Attachments
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Note, :attachment]"
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

      # Markdown
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, Project]"
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
	  sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"
	  
      ```

      Currently this has to be executed manually and it will allow you to
      migrate the existing uploads to the object storage, but all new
      uploads will still be stored on the local disk. In the future
      you will be given an option to define a default storage for all
      new files.

[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[restart gitlab]: restart_gitlab.md#installations-from-source "How to restart GitLab"
[eep]: https://about.gitlab.com/gitlab-ee/ "GitLab Enterprise Edition Premium"
[ee-3867]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3867
