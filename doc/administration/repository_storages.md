# Repository storages

> [Introduced][ce-4578] in GitLab 8.10.

GitLab allows you to define multiple repository storage paths to distribute the
storage load between several mount points.

>**Notes:**
>
- You must have at least one storage path called `default`.
- The paths are defined in key-value pairs. The key is an arbitrary name you
  can pick to name the file path.
- The target directories and any of its subpaths must not be a symlink.

## Configure GitLab

>**Warning:**
- In order for backups to work correctly the storage path must **not** be a
  mount point and the GitLab user should have correct permissions for the parent
  directory of the path.

Edit the configuration files and add the full paths of the alternative repository
storage paths. In the example below we added two more mountpoints that we named
`nfs` and `cephfs` respectively.

**For installations from source**

1. Edit `gitlab.yml` and add the storage paths:

    ```yaml
    repositories:
      # Paths where repositories can be stored. Give the canonicalized absolute pathname.
      # NOTE: REPOS PATHS MUST NOT CONTAIN ANY SYMLINK!!!
      storages: # You must have at least a 'default' storage path.
        default: /home/git/repositories
        nfs: /mnt/nfs/repositories
        cephfs: /mnt/cephfs/repositories
    ```

1. [Restart GitLab] for the changes to take effect.

The `gitlab_shell: repos_path` entry in `gitlab.yml` will be deprecated and
replaced by `repositories: storages` in the future, so if you are upgrading
from a version prior to 8.10, make sure to add the configuration as described
in the step above. After you make the changes and confirm they are working,
you can remove:

```yaml
repos_path: /home/git/repositories
```

which is located under the `gitlab_shell` section.

---

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb` by appending the rest of the paths to the
   default one:

    ```ruby
    git_data_dirs({
      "default" => "/var/opt/gitlab/git-data",
      "nfs" => "/mnt/nfs/git-data",
      "cephfs" => "/mnt/cephfs/git-data"
    })
    ```

    Note that Omnibus stores the repositories in a `repositories` subdirectory
    of the `git-data` directory.

## Choose where new project repositories will be stored

Once you set the multiple storage paths, you can choose where new projects will
be stored via the **Application Settings** in the Admin area.

![Choose repository storage path in Admin area](img/repository_storages_admin_ui.png)

[ce-4578]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/4578
[restart gitlab]: restart_gitlab.md#installations-from-source
[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure
