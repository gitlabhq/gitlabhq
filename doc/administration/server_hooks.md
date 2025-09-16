---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Git server hooks
description: Configure Git server hooks.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/372991) from server hooks to Git server hooks in GitLab 15.6.

{{< /history >}}

Git server hooks run custom logic on the GitLab server. You can use them to run Git-related tasks such as:

- Enforcing specific commit policies.
- Performing tasks based on the state of the repository.

Git server hooks use `pre-receive`, `post-receive`, and `update` Git server-side hooks.

GitLab administrators configure server hooks using the `gitaly` command, which also:

- Is used to launch a Gitaly server.
- Provides several subcommands.
- Connects to the Gitaly gRPC API.

If you don't have access to the `gitaly` command, alternatives to server hooks include:

- [Webhooks](../user/project/integrations/webhooks.md).
- [GitLab CI/CD](../ci/_index.md).
- [Push rules](../user/project/repository/push_rules.md), for a user-configurable Git hook interface.

{{< alert type="note" >}}

[Geo](geo/_index.md) doesn't replicate server hooks to secondary nodes.

{{< /alert >}}

## Prerequisites

- The [storage name](gitaly/configure_gitaly.md#gitlab-requires-a-default-repository-storage), path to the Gitaly configuration file
  (default is `/var/opt/gitlab/gitaly/config.toml` on Linux package instances), and the
  [repository relative path](repository_storage_paths.md#from-project-name-to-hashed-path) for the repository.
- Any language runtimes and utilities that are required by the hooks must be installed on each of the servers that run Gitaly.

## Set server hooks for a repository

To set server hooks for a repository:

1. Create tarball containing custom hooks:
   1. Write the code to make the server hook function as expected. Git server hooks can be in any programming language.
      Ensure the shebang at the top reflects the language type. For example, if the script is in Ruby the shebang is
      probably `#!/usr/bin/env ruby`.

      - To create a single server hook, create a file with a name that matches the hook type. For example, for a
        `pre-receive` server hook, the filename should be `pre-receive` with no extension.
      - To create many server hooks, create a directory for the hooks that matches the hook type. For example, for a
        `pre-receive` server hook, the directory name should be `pre-receive.d`. Put the files for the hook in that
        directory.

   1. Ensure the server hook files are executable and do not match the backup file pattern (`*~`). The server hooks be
      in a `custom_hooks` directory that is at the root of the tarball.
   1. Create the custom hooks archive with the tar command. For example, `tar -cf custom_hooks.tar custom_hooks`.
1. Run the `hooks set` subcommand with required options to set the Git hooks for the repository. For example:

   ```shell
   cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
   ```

   - A path to a valid Gitaly configuration for the node is required to connect to the node and provided to the `--config` flag.
   - Custom hooks tarball must be passed through `stdin`. For example:

     ```shell
     cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
     ```

1. If you are using Gitaly Cluster (Praefect), you must run `hooks set` subcommand on all Gitaly nodes.

If you implemented the server hook code correctly, it should execute when the Git hook is next triggered.

### Server hooks on a Gitaly Cluster (Praefect)

If you use Gitaly Cluster (Praefect), an individual repository may be replicated to multiple Gitaly storages in Praefect.
Consequently, the hook scripts must be copied to every Gitaly node that has a replica of the repository.
To accomplish this, follow the same steps for setting custom repository hooks for the applicable version and repeat for each storage.

The location to copy the scripts to depends on where repositories are stored. New repositories are created using
Praefect-generated replica paths which are not the hashed storage path. To identify the replica path,
[query the Praefect repository metadata](gitaly/praefect/troubleshooting.md#view-repository-metadata) by using
`-relative-path` option to specify the expected GitLab hashed storage path.

## Create global server hooks for all repositories

To create a Git hook that applies to all repositories, set a global server hook. Global server hooks also apply to:

- Project and group wiki repositories. Their storage directory names are in the format `<id>.wiki.git`.
- Design management repositories under a project. Their storage directory names are in the format `<id>.design.git`.

### Choose a server hook directory

Before creating a global server hook, you must choose a directory for it.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

The directory is set in `gitlab.rb` under `gitaly['configuration'][:hooks][:custom_hooks_dir]`. You can either:

- Use the default suggestion of the `/var/opt/gitlab/gitaly/custom_hooks` directory by uncommenting it.
- Add your own setting.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

- The directory is set in `gitaly/config.toml` under the `[hooks]` section. However, GitLab honors the
  `custom_hooks_dir` value in `gitlab-shell/config.yml` if the value in `gitaly/config.toml` is blank or non-existent.
- The default directory is `/home/git/gitlab-shell/hooks`.

{{< /tab >}}

{{< /tabs >}}

### Create the global server hook

To create a global server hook for all repositories:

1. On the GitLab server, go to the configured global server hook directory.
1. In the configured global server hook directory, create a directory for the hooks that matches the hook type. For example, for a `pre-receive` server hook, the directory name should be `pre-receive.d`.
1. Inside this new directory, add your server hooks. Git server hooks can be in any programming language. Ensure the
   shebang (`#!`) at the top reflects the language type. For example, if the script is in Ruby the shebang is probably `#!/usr/bin/env ruby`.
1. Make the hook file executable, ensure that it's owned by the Git user, and ensure it does not match the backup file
   pattern (`*~`).

If the server hook code is properly implemented, it should execute when the Git hook is next triggered. Hooks are executed in alphabetical order by filename in the hook type
subdirectories.

## Remove server hooks for a repository

To remove server hooks, pass an empty tarball to `hook set` to indicate that the repository should contain no hooks. For example:

```shell
cat empty_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
```

## Chained server hooks

GitLab can execute server hooks in a chain. GitLab searches for and executes server hooks in the following order:

- Built-in GitLab server hooks. These server hooks are not customizable by users.
- `<project>.git/custom_hooks/<hook_name>`: Per-project hooks. This location is kept for backwards compatibility.
- `<project>.git/custom_hooks/<hook_name>.d/*`: Location for per-project hooks.
- `<custom_hooks_dir>/<hook_name>.d/*`: Location for all executable global hook files except editor backup files.

In a server hooks directory, hooks:

- Are executed in alphabetical order.
- Stop executing when a hook exits with a non-zero value.

## Environment variables available to server hooks

You can pass any environment variable to server hooks, but you should only rely on supported environment variables.

The following GitLab environment variables are supported for all server hooks:

| Environment variable | Description |
|:---------------------|:------------|
| `GL_ID`              | GitLab identifier of user or SSH key that initiated the push. For example, `user-2234` or `key-4`. |
| `GL_PROJECT_PATH`    | GitLab project path. |
| `GL_PROTOCOL`        | Protocol used for this change. One of: `http` (Git `push` using HTTP), `ssh` (Git `push` using SSH), or `web` (all other actions). |
| `GL_REPOSITORY`      | GitLab project ID with a prefix of `project-`. For example, `project-1234` |
| `GL_USERNAME`        | GitLab username of the user that initiated the push. |

The following Git environment variables are supported for `pre-receive` and `post-receive` server hooks:

| Environment variable               | Description |
|:-----------------------------------|:------------|
| `GIT_ALTERNATE_OBJECT_DIRECTORIES` | Alternate object directories in the [quarantine environment](https://git-scm.com/docs/git-receive-pack#_quarantine_environment). |
| `GIT_OBJECT_DIRECTORY`             | GitLab project path in the quarantine environment. |
| `GIT_PUSH_OPTION_COUNT`            | Number of [push options](../topics/git/commit.md#push-options). |
| `GIT_PUSH_OPTION_<i>`              | Value of a specific push option where `<i>` is from `0` to one less than the value defined in `GIT_PUSH_OPTION_COUNT`. |

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

## Related topics

- [System hooks](system_hooks.md)
- [File hooks](file_hooks.md)
- [Praefect-generated replica paths](gitaly/praefect/_index.md#praefect-generated-replica-paths)
