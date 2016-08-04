# Build artifacts administration

>**Notes:**
>- Introduced in GitLab 8.2 and GitLab Runner 0.7.0.
>- Starting from GitLab 8.4 and GitLab Runner 1.0, the artifacts archive format
   changed to `ZIP`.
>- This is the administration documentation. For the user guide see
   [user/project/builds/artifacts.md](../user/project/builds/artifacts.md).

Artifacts is a list of files and directories which are attached to a build
after it completes successfully. This feature is enabled by default in all
GitLab installations. Keep reading if you want to know how to disable it.

## Disabling build artifacts

To disable artifacts site-wide, follow the steps below.

---

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['artifacts_enabled'] = false
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

    ```yaml
    artifacts:
      enabled: false
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.

## Storing build artifacts

After a successful build, GitLab Runner uploads an archive containing the build
artifacts to GitLab.

To change the location where the artifacts are stored, follow the steps below.

---

**In Omnibus installations:**

_The artifacts are stored by default in
`/var/opt/gitlab/gitlab-rails/shared/artifacts`._

1. To change the storage path for example to `/mnt/storage/artifacts`, edit
   `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

_The artifacts are stored by default in
`/home/git/gitlab/shared/artifacts`._

1. To change the storage path for example to `/mnt/storage/artifacts`, edit
   `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

    ```yaml
    artifacts:
      enabled: true
      path: /mnt/storage/artifacts
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.

## Set the maximum file size of the artifacts

Provided the artifacts are enabled, you can change the maximum file size of the
artifacts through the [Admin area settings](../user/admin_area/settings/continuous_integration#maximum-artifacts-size).

[reconfigure gitlab]: restart_gitlab.md "How to restart GitLab"
[restart gitlab]: restart_gitlab.md "How to restart GitLab"
