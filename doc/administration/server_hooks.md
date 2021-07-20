---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
disqus_identifier: 'https://docs.gitlab.com/ee/administration/custom_hooks.html'
---

# Server hooks **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/196051) in GitLab 12.8 replacing Custom Hooks.

Git supports hooks that are executed on different actions. These hooks run on the server and can be
used to enforce specific commit policies or perform other tasks based on the state of the
repository.

Git supports the following hooks:

- `pre-receive`
- `post-receive`
- `update`

See [the Git documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#_server_side_hooks)
for more information about each hook type.

Server-side Git hooks can be configured for:

- [A single repository](#create-a-server-hook-for-a-repository).
- [All repositories](#create-a-global-server-hook-for-all-repositories).

Note the following about server hooks:

- Server hooks must be configured on the file system of the GitLab server. Only GitLab server
  administrators are able to complete these tasks. If you don't have file system access, see
  possible alternatives such as:
  - [Webhooks](../user/project/integrations/webhooks.md).
  - [GitLab CI/CD](../ci/index.md).
  - [Push Rules](../push_rules/push_rules.md), for a user-configurable Git hook
    interface.
- Server hooks aren't replicated to [Geo](geo/index.md) secondary nodes.

## Create a server hook for a repository

If you are not using [hashed storage](repository_storage_types.md#hashed-storage), the project's
repository directory might not exactly match the instructions below. In that case:

- For an installation from source, the path is usually
  `/home/git/repositories/<group>/<project>.git`.
- For Omnibus GitLab installs, the path is usually
  `/var/opt/gitlab/git-data/repositories/<group>/<project>.git`.

Follow the steps below to set up a server-side hook for a repository:

1. Go to **Admin area > Projects** and select the project you want to add a server hook to.
1. Locate the **Gitaly relative path** on the page that appears. This is where the server hook
   must be implemented. For information on interpreting the relative path, see
   [Translate hashed storage paths](repository_storage_types.md#translate-hashed-storage-paths).
1. On the file system, create a new directory in this location called `custom_hooks`.
1. Inside the new `custom_hooks` directory, create a file with a name matching the hook type. For
   example, for a pre-receive hook the filename should be `pre-receive` with no extension.
1. Make the hook file executable and ensure that it's owned by the Git user.
1. Write the code to make the server hook function as expected. Hooks can be in any language. Ensure
   the ["shebang"](https://en.wikipedia.org/wiki/Shebang_(Unix)) at the top properly reflects the
   language type. For example, if the script is in Ruby the shebang is probably
   `#!/usr/bin/env ruby`.

Assuming the hook code is properly implemented, the hook code is executed as appropriate.

## Create a global server hook for all repositories

To create a Git hook that applies to all of the repositories in your instance, set a global server
hook. The default global server hook directory is in the GitLab Shell directory. Any
hook added there applies to all repositories, including:

- [Project and group wiki](../user/project/wiki/index.md) repositories,
  whose storage directory names are in the format `<id>.wiki.git`.
- [Design management](../user/project/issues/design_management.md) repositories under a
  project, whose storage directory names are in the format `<id>.design.git`.

The default directory:

- For an installation from source is usually `/home/git/gitlab-shell/hooks`.
- For Omnibus GitLab installs is usually `/opt/gitlab/embedded/service/gitlab-shell/hooks`.

To use a different directory for global server hooks, set `custom_hooks_dir` in Gitaly
configuration:

- For Omnibus installations, this is set in `gitlab.rb`.
- For source installations, the configuration location depends on the GitLab version. For:
  - GitLab 13.0 and earlier, this is set in `gitlab-shell/config.yml`.
  - GitLab 13.1 and later, this is set in `gitaly/config.toml` under the `[hooks]` section.

NOTE:
The `custom_hooks_dir` value in `gitlab-shell/config.yml` is still honored in GitLab 13.1 and later
if the value in `gitaly/config.toml` is blank or non-existent.

Follow the steps below to set up a global server hook for all repositories:

1. On the GitLab server, navigate to the configured global server hook directory.
1. Create a new directory in this location. Depending on the type of hook, it can be either a
   `pre-receive.d`, `post-receive.d`, or `update.d` directory.
1. Inside this new directory, add your hook. Hooks can be in any language. Ensure the
   ["shebang"](https://en.wikipedia.org/wiki/Shebang_(Unix)) at the top properly reflects the
   language type. For example, if the script is in Ruby the shebang is probably
   `#!/usr/bin/env ruby`.
1. Make the hook file executable and ensure that it's owned by the Git user.

Now test the hook to check whether it is functioning properly.

## Chained hooks

Server hooks set [per project](#create-a-server-hook-for-a-repository) or
[globally](#create-a-global-server-hook-for-all-repositories) can be executed in a chain.

Server hooks are searched for and executed in the following order of priority:

- Built-in GitLab server hooks. These are not user-customizable.
- `<project>.git/custom_hooks/<hook_name>`: Per-project hooks. This was kept for backwards
  compatibility.
- `<project>.git/custom_hooks/<hook_name>.d/*`: Location for per-project hooks.
- `<custom_hooks_dir>/<hook_name>.d/*`: Location for all executable global hook files
  except editor backup files.

Within a directory, server hooks:

- Are executed in alphabetical order.
- Stop executing when a hook exits with a non-zero value.

`<hook_name>.d` must be either `pre-receive.d`, `post-receive.d`, or `update.d` to work properly.
Any other names are ignored.

Files in `.d` directories must be executable and not match the backup file pattern (`*~`).

For `<project>.git` you need to [translate](repository_storage_types.md#translate-hashed-storage-paths)
your project name into the hashed storage format that GitLab uses.

## Environment Variables

The following set of environment variables are available to server hooks.

| Environment variable | Description                                                                 |
|:---------------------|:----------------------------------------------------------------------------|
| `GL_ID`              | GitLab identifier of user that initiated the push. For example, `user-2234` |
| `GL_PROJECT_PATH`    | (GitLab 13.2 and later) GitLab project path                                 |
| `GL_PROTOCOL`        | (GitLab 13.2 and later) Protocol used for this change. One of: `http` (Git Push using HTTP), `ssh` (Git Push using SSH), or `web` (all other actions). |
| `GL_REPOSITORY`      | `project-<id>` where `id` is the ID of the project                          |
| `GL_USERNAME`        | GitLab username of the user that initiated the push                         |

Pre-receive and post-receive server hooks can also access the following Git environment variables.

| Environment variable               | Description                                                                                                                                                            |
|:-----------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GIT_ALTERNATE_OBJECT_DIRECTORIES` | Alternate object directories in the quarantine environment. See [Git `receive-pack` documentation](https://git-scm.com/docs/git-receive-pack#_quarantine_environment). |
| `GIT_OBJECT_DIRECTORY`             | GitLab project path in the quarantine environment. See [Git `receive-pack` documentation](https://git-scm.com/docs/git-receive-pack#_quarantine_environment).          |
| `GIT_PUSH_OPTION_COUNT`            | Number of push options. See [Git `pre-receive` documentation](https://git-scm.com/docs/githooks#pre-receive).                                                          |
| `GIT_PUSH_OPTION_<i>`              | Value of push options where `i` is from `0` to `GIT_PUSH_OPTION_COUNT - 1`. See [Git `pre-receive` documentation](https://git-scm.com/docs/githooks#pre-receive).      |

NOTE:
While other environment variables can be passed to server hooks, your application should not rely on
them as they can change.

## Custom error messages

To have custom error messages appear in the GitLab UI when a commit is declined or an error occurs
during the Git hook, your script should:

- Send the custom error messages to either the script's `stdout` or `stderr`.
- Prefix each message with `GL-HOOK-ERR:` with no characters appearing before the prefix.

### Example custom error message

This hook script written in Bash generates the following message in the GitLab UI:

```shell
#!/bin/sh
echo "GL-HOOK-ERR: My custom error message.";
exit 1
```

![Custom message from custom Git hook](img/custom_hooks_error_msg.png)
