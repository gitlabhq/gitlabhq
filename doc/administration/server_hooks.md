---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
disqus_identifier: 'https://docs.gitlab.com/ee/administration/custom_hooks.html'
---

# Server hooks **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/196051) in GitLab 12.8 replacing Custom Hooks.

Server hooks run custom logic on the GitLab server. Users can use them to run Git-related tasks such as:

- Enforcing specific commit policies.
- Performing tasks based on the state of the repository.

Server hooks use `pre-receive`, `post-receive`, and `update`
[Git server-side hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#_server_side_hooks).

GitLab administrators configure server hooks on the file system of the GitLab server. If you don't have file system access,
alternatives to server hooks include:

- [Webhooks](../user/project/integrations/webhooks.md).
- [GitLab CI/CD](../ci/index.md).
- [Push rules](../user/project/repository/push_rules.md), for a user-configurable Git hook interface.

[Geo](geo/index.md) doesn't replicate server hooks to secondary nodes.

## Create server hooks for a repository

To create server hooks for a repository:

1. On the top bar, select **Menu > Admin**.
1. Go to **Overview > Projects** and select the project you want to add a server hook to.
1. On the page that appears, locate the value of **Gitaly relative path**. This path is where server hooks must be located.
   - If you are using [hashed storage](repository_storage_types.md#hashed-storage), see
     [Translate hashed storage paths](repository_storage_types.md#translate-hashed-storage-paths) for information on
     interpreting the relative path.
   - If you are not using [hashed storage](repository_storage_types.md#hashed-storage):
     - For Omnibus GitLab installations, the path is usually `/var/opt/gitlab/git-data/repositories/<group>/<project>.git`.
     - For an installation from source, the path is usually `/home/git/repositories/<group>/<project>.git`.
1. On the file system, create a new directory in the correct location called `custom_hooks`.
1. In the new `custom_hooks` directory:
   - To create a single server hook, create a file with a name that matches the hook type. For example, for a
     `pre-receive` server hook, the filename should be `pre-receive` with no extension.
   - To create many server hooks, create a directory for the hooks that matches the hook type. For example, for a
     `pre-receive` server hook, the directory name should be `pre-receive.d`. Put the files for the hook in that directory.
1. Make the server hook files executable and ensure that they are owned by the Git user.
1. Write the code to make the server hook function as expected. Server hooks can be in any programming language. Ensure
   the [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) at the top reflects the language type. For
   example, if the script is in Ruby the shebang is probably `#!/usr/bin/env ruby`.
1. Make the hook file executable, ensure that it's owned by the Git user, and ensure it does not match the backup file
   pattern (`*~`).

If the server hook code is properly implemented, it should execute when the Git hook is next triggered.

## Create global server hooks for all repositories

To create a Git hook that applies to all repositories, set a global server hook. The default global server hook directory
is in the GitLab Shell directory. Any server hook added there applies to all repositories, including:

- [Project and group wiki](../user/project/wiki/index.md) repositories. Their storage directory names are in the format
  `<id>.wiki.git`.
- [Design management](../user/project/issues/design_management.md) repositories under a project. Their storage directory
  names are in the format `<id>.design.git`.

### Choose a server hook directory

Before creating a global server hook, you must choose a directory for it. The default global server hook directory:

- For Omnibus GitLab installations is usually `/opt/gitlab/embedded/service/gitlab-shell/hooks`.
- For an installation from source is usually `/home/git/gitlab-shell/hooks`.

To use a different directory for global server hooks, set `custom_hooks_dir` in Gitaly configuration:

- For Omnibus installations, set in `gitlab.rb`.
- For source installations, the configuration location depends on the GitLab version. For:
  - GitLab 13.0 and earlier, set in `gitlab-shell/config.yml`.
  - GitLab 13.1 and later, set in `gitaly/config.toml` under the `[hooks]` section. However, GitLab honors the
    `custom_hooks_dir` value in `gitlab-shell/config.yml` if the value in `gitaly/config.toml` is blank or non-existent.

### Create the global server hook

To create a global server hook for all repositories:

1. On the GitLab server, go to the configured global server hook directory.
1. In the configured global server hook directory:
   - To create a single server hook, create a file with a name that matches the hook type. For example, for a
     `pre-receive` server hook, the filename should be `pre-receive` with no extension.
   - To create many server hooks, create a directory for the hooks that matches the hook type. For example, for a
     `pre-receive` server hook, the directory name should be `pre-receive.d`. Put the files for the hook in that directory.
1. Inside this new directory, add your server hook. Server hooks can be in any programming language. Ensure the
   [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) at the top reflects the language type. For example, if the
   script is in Ruby the shebang is probably `#!/usr/bin/env ruby`.
1. Make the hook file executable, ensure that it's owned by the Git user, and ensure it does not match the backup file
   pattern (`*~`).

If the server hook code is properly implemented, it should execute when the Git hook is next triggered.

## Chained server hooks

GitLab can execute server hooks in a chain. GitLab searches for and executes server hooks in the following order:

- Built-in GitLab server hooks. These server hooks are not customizable by users.
- `<project>.git/custom_hooks/<hook_name>`: Per-project hooks. This location is kept for backwards compatibility.
- `<project>.git/custom_hooks/<hook_name>.d/*`: Location for per-project hooks.
- `<custom_hooks_dir>/<hook_name>.d/*`: Location for all executable global hook files except editor backup files.

Within a server hooks directory, hooks:

- Are executed in alphabetical order.
- Stop executing when a hook exits with a non-zero value.

## Environment variables available to server hooks

You can pass any environment variable to server hooks, but you should only rely on supported environment variables.

The following GitLab environment variables are supported for all server hooks:

| Environment variable | Description                                                                                                                                                |
|:---------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GL_ID`              | GitLab identifier of user that initiated the push. For example, `user-2234`.                                                                               |
| `GL_PROJECT_PATH`    | (GitLab 13.2 and later) GitLab project path.                                                                                                               |
| `GL_PROTOCOL`        | (GitLab 13.2 and later) Protocol used for this change. One of: `http` (Git `push` using HTTP), `ssh` (Git `push` using SSH), or `web` (all other actions). |
| `GL_REPOSITORY`      | `project-<id>` where `id` is the ID of the project.                                                                                                        |
| `GL_USERNAME`        | GitLab username of the user that initiated the push.                                                                                                       |

The following Git environment variables are supported for `pre-receive` and `post-receive` server hooks:

| Environment variable               | Description                                                                                                                                                            |
|:-----------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GIT_ALTERNATE_OBJECT_DIRECTORIES` | Alternate object directories in the quarantine environment. See [Git `receive-pack` documentation](https://git-scm.com/docs/git-receive-pack#_quarantine_environment). |
| `GIT_OBJECT_DIRECTORY`             | GitLab project path in the quarantine environment. See [Git `receive-pack` documentation](https://git-scm.com/docs/git-receive-pack#_quarantine_environment).          |
| `GIT_PUSH_OPTION_COUNT`            | Number of [push options](../user/project/push_options.md). See [Git `pre-receive` documentation](https://git-scm.com/docs/githooks#pre-receive).                                                          |
| `GIT_PUSH_OPTION_<i>`              | Value of [push options](../user/project/push_options.md) where `i` is from `0` to `GIT_PUSH_OPTION_COUNT - 1`. See [Git `pre-receive` documentation](https://git-scm.com/docs/githooks#pre-receive).      |

## Custom error messages

You can have custom error messages appear in the GitLab UI when a commit is declined or an error occurs during the Git
hook. To display a custom error message, your script must:

- Send the custom error messages to either the script's `stdout` or `stderr`.
- Prefix each message with `GL-HOOK-ERR:` with no characters appearing before the prefix.

For example:

```shell
#!/bin/sh
echo "GL-HOOK-ERR: My custom error message.";
exit 1
```
