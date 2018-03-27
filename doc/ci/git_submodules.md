# Using Git submodules with GitLab CI

> **Notes:**
- GitLab 8.12 introduced a new [CI job permissions model][newperms] and you
  are encouraged to upgrade your GitLab instance if you haven't done already.
  If you are **not** using GitLab 8.12 or higher, you would need to work your way
  around submodules in order to access the sources of e.g., `gitlab.com/group/project`
  with the use of [SSH keys](ssh_keys/README.md).
- With GitLab 8.12 onward, your permissions are used to evaluate what a CI job
  can access. More information about how this system works can be found in the
  [Jobs permissions model](../user/permissions.md#job-permissions).
- The HTTP(S) Git protocol [must be enabled][gitpro] in your GitLab instance.

## Configuring the `.gitmodules` file

If dealing with [Git submodules][gitscm], your project will probably have a file
named `.gitmodules`.

Let's consider the following example:

1. Your project is located at `https://gitlab.com/secret-group/my-project`.
1. To checkout your sources you usually use an SSH address like
   `git@gitlab.com:secret-group/my-project.git`.
1. Your project depends on `https://gitlab.com/group/project`, which you want
   to include as a submodule.

If you are using GitLab 8.12+ and your submodule is on the same GitLab server,
you must update your `.gitmodules` file to use **relative URLs**.
Since Git allows the usage of relative URLs for your `.gitmodules` configuration,
this easily allows you to use HTTP(S) for cloning all your CI jobs and SSH
for all your local checkouts. The `.gitmodules` would look like:

```ini
[submodule "project"]
  path = project
  url = ../../group/project.git
```

The above configuration will instruct Git to automatically deduce the URL that
should be used when cloning sources. Whether you use HTTP(S) or SSH, Git will use
that same channel and it will allow to make all your CI jobs use HTTP(S)
(because GitLab CI only uses HTTP(S) for cloning your sources), and all your local
clones will continue using SSH.

For all other submodules not located on the same GitLab server, use the full
HTTP(S) protocol URL:

```ini
[submodule "project-x"]
  path = project-x
  url = https://gitserver.com/group/project-x.git
```

Once `.gitmodules` is correctly configured, you can move on to
[configuring your `.gitlab-ci.yml`](#using-git-submodules-in-your-ci-jobs).

## Using Git submodules in your CI jobs

There are a few steps you need to take in order to make submodules work
correctly with your CI jobs:

1. First, make sure you have used [relative URLs](#configuring-the-gitmodules-file)
   for the submodules located in the same GitLab server.
1. Next, if you are using `gitlab-runner` v1.10+, you can set the
   `GIT_SUBMODULE_STRATEGY` variable to either `normal` or `recursive` to tell
   the runner to fetch your submodules before the job:
    ```yaml
    variables:
      GIT_SUBMODULE_STRATEGY: recursive
    ```
    See the [`.gitlab-ci.yml` reference](yaml/README.md#git-submodule-strategy)
    for more details about `GIT_SUBMODULE_STRATEGY`.

1. If you are using an older version of `gitlab-runner`, then use
   `git submodule sync/update` in `before_script`:

    ```yaml
    before_script:
      - git submodule sync --recursive
      - git submodule update --init --recursive
    ```

    `--recursive` should be used in either both or none (`sync/update`) depending on
    whether you have recursive submodules.

The rationale to set the `sync` and `update` in `before_script` is because of
the way Git submodules work. On a fresh Runner workspace, Git will set the
submodule URL including the token in `.git/config`
(or `.git/modules/<submodule>/config`) based on `.gitmodules` and the current
remote URL. On subsequent jobs on the same Runner, `.git/config` is cached
and already contains a full URL for the submodule, corresponding to the previous
job, and to **a token from a previous job**. `sync` allows to force updating
the full URL.

[gitpro]: ../user/admin_area/settings/visibility_and_access_controls.md#enabled-git-access-protocols
[gitscm]: https://git-scm.com/book/en/v2/Git-Tools-Submodules "Git submodules documentation"
[newperms]: ../user/project/new_ci_build_permissions_model.md
