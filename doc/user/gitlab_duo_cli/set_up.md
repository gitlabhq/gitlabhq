---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Install and authenticate the GitLab Duo CLI.
title: Set up the GitLab Duo CLI
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can use the GitLab Duo CLI through the [GitLab CLI](https://docs.gitlab.com/cli/) (`glab`). With the GitLab CLI, you get access to other GitLab features and you only need to authenticate once, using OAuth or a personal access token.

Alternatively, you can install and use the GitLab Duo CLI (`duo`) as a standalone AI tool, authenticating
separately with a personal access token.

Both setups support interactive and headless modes, along with all GitLab Duo CLI options, commands,
and functionality.

## Prerequisites

- GitLab 19.2 or later.
- The [prerequisites for GitLab Duo Agent Platform](../duo_agent_platform/_index.md#prerequisites).
- For GitLab Self-Managed and GitLab Dedicated, make sure that GitLab Duo CLI
  access is [turned on](_index.md#manage-gitlab-duo-cli-access).

> [!note]
> If you are on GitLab 18.11 to 19.1, you can use the latest version of the GitLab Duo CLI by turning on [beta and experimental features](../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features).

## With the GitLab CLI

Prerequisites:

- [GitLab CLI](https://docs.gitlab.com/cli/) 1.107.0 or later.
- GitLab CLI is [authenticated](https://docs.gitlab.com/cli/#authenticate-with-gitlab).

To set up the GitLab Duo CLI for use through the GitLab CLI:

1. Run the `glab` command for the GitLab Duo CLI:

   ```shell
   glab duo cli
   ```

1. Follow the prompts to install the GitLab Duo CLI binary.

The GitLab CLI automatically handles authentication, so you can start using the GitLab Duo CLI
immediately.

## Without the GitLab CLI

To use the GitLab Duo CLI as a standalone tool, install it and then authenticate.

### Install

To install the GitLab Duo CLI as a compiled binary, download and run the install script.

On macOS and Linux:

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

On Windows:

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

### Authenticate

> [!note]
> If `glab` is already installed and authenticated on your system when you first run `duo`, `duo`
> automatically uses `glab` as a credential helper. You do not need to authenticate separately. This
> requires `glab` 1.85.2 or later and `duo` 8.68.0 or later.
>
> If you authenticated `duo` before this feature was available and want to use `glab` as a
> credential helper instead, delete your authentication settings from `~/.gitlab/storage.json`.

Prerequisites:

- A [personal access token](../profile/personal_access_tokens.md) with `api` permissions.

To authenticate:

1. Run `duo` in your terminal. The first time you run the GitLab Duo CLI, a configuration screen
   appears.
1. Enter a **GitLab Instance URL** and then press <kbd>Enter</kbd>:
   - For GitLab.com, enter `https://gitlab.com`.
   - For GitLab Self-Managed or GitLab Dedicated, enter your instance URL.
1. For **GitLab Token**, enter your personal access token.
1. To save and exit the CLI, press <kbd>Enter</kbd>.
1. To restart the CLI, run `duo` in your terminal.

To modify the configuration after initial setup, use `duo config edit`.

### Authenticate with environment variables

Prerequisites:

- A [personal access token](../profile/personal_access_tokens.md) with `api` permissions.

The GitLab Duo CLI respects standard proxy environment variables:

- `HTTP_PROXY` or `http_proxy`: Proxy URL for HTTP requests.
- `HTTPS_PROXY` or `https_proxy`: Proxy URL for HTTPS requests.
- `NO_PROXY` or `no_proxy`: Comma-separated list of hosts to exclude from proxying.

To authenticate with environment variables:

1. Set `GITLAB_TOKEN` or `GITLAB_OAUTH_TOKEN` to your personal access token.

   ```shell
   export GITLAB_TOKEN="<your-personal-access-token>"
   ```

1. Optional. Set `GITLAB_BASE_URL` or `GITLAB_URL` to your custom GitLab instance URL, for example `https://gitlab.example.com`. The default is `https://gitlab.com`.

   ```shell
   export GITLAB_BASE_URL="<your-instance-url>"
   ```

This method is useful for headless mode, CI/CD pipelines, and scripted workflows
where interactive authentication is not possible.

## Related topics

- [GitLab Duo CLI complete reference](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [Security considerations for editor extensions](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
