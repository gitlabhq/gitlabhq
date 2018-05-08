# Job traces (logs)

By default, all job traces (logs) are saved to `/var/opt/gitlab/gitlab-ci/builds`
and `/home/git/gitlab/builds` for Omnibus packages and installations from source
respectively. The job logs are organized by year and month (for example, `2017_03`),
and then by project ID.

There isn't a way to automatically expire old job logs, but it's safe to remove
them if they're taking up too much space. If you remove the logs manually, the
job output in the UI will be empty.

## Changing the job traces location

To change the location where the job logs will be stored, follow the steps below.

**In Omnibus installations:**

1.  Edit `/etc/gitlab/gitlab.rb` and add or amend the following line:

    ```
    gitlab_ci['builds_directory'] = '/mnt/to/gitlab-ci/builds'
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

---

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following lines:

    ```yaml
    gitlab_ci:
      # The location where build traces are stored (default: builds/).
      # Relative paths are relative to Rails.root.
      builds_path: path/to/builds/
    ```

1. Save the file and [restart GitLab][] for the changes to take effect.

[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[restart gitlab]: restart_gitlab.md#installations-from-source "How to restart GitLab"
