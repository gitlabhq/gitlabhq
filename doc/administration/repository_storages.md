# Repository storages

GitLab allows you to define repository storage paths to enable distribution of
storage load between several mount points. You can choose where new projects are
stored via the `Application Settings` in the Admin interface.

## For installations from source

Add your repository storage paths in your `gitlab.yml` under repositories -> storages, using key -> value pairs.

>**Notes:**
- You must have at least one storage path called `default`.
- In order for backups to work correctly the storage path must **not** be a
mount point and the GitLab user should have correct permissions for the parent
directory of the path.

## For omnibus installations

Follow the instructions at https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/configuration.md#storing-git-data-in-an-alternative-directory
