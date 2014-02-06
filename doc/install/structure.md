# GitLab directory structure

This is the directory structure you will end up with following the instructions in the Installation Guide.

    |-- home
    |   |-- git
    |       |-- .ssh
    |       |-- gitlab
    |       |-- gitlab-satellites
    |       |-- gitlab-shell
    |       |-- repositories

* `/home/git/.ssh` - contains openssh settings.  Specifically the `authorized_keys` file managed by gitlab-shell.
* `/home/git/gitlab` - GitLab core software.
* `/home/git/gitlab-satellites` - checked out repositories for merge requests and file editing from web UI.  This can be treated as a temporary files directory.
* `/home/git/gitlab-shell` - Core add-on component of gitlab.  Maintains SSH cloning and other functionality.
* `/home/git/repositories` - bare repositories for all projects organized by namespace.  This is where the git repositories which are pushed/pulled are maintained for all projects.  **This area is critical data for projects.  [Keep a backup](../raketasks/backup_restore.md)**

*Note: the default locations for gitlab-satellites and repositories can be configured in `config/gitlab.yml` of gitlab and `config.yml` of gitlab-shell.*

To see a more in-depth overview see the [GitLab architecture doc](../development/architecture.md).
