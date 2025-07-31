---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use the GitLab CLI (glab) to perform common GitLab actions in your terminal.
title: GitLab CLI - `glab`
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`glab` is an open source GitLab CLI tool. It brings GitLab to your terminal:
next to where you are already working with Git and your code, without
switching between windows and browser tabs.

- Work with issues.
- Work with merge requests.
- Watch running pipelines directly from your CLI.

![command example](img/glabgettingstarted_v15_7.gif)

The GitLab CLI uses commands structured like `glab <command> <subcommand> [flags]`
to perform many of the actions you usually do from the GitLab user interface:

```shell
# Sign in
glab auth login --stdin < token.txt

# View a list of issues
glab issue list

# Create merge request for issue 123
glab mr create 123

# Check out the branch for merge request 243
glab mr checkout 243

# Watch the pipeline in progress
glab pipeline ci view

# View, approve, and merge the merge request
glab mr view
glab mr approve
glab mr merge
```

## Core commands

- [`glab alias`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/alias): Create, list, and delete aliases.
- [`glab api`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/api): Make authenticated requests to the GitLab API.
- [`glab auth`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/auth): Manage the authentication state of the CLI.
- [`glab changelog`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/changelog): Interact with the changelog API.
- [`glab check-update`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/check-update): Check for updates to the CLI.
- [`glab ci`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/ci): Work with GitLab CI/CD pipelines and jobs.
- [`glab cluster`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/cluster): Manage GitLab agents for Kubernetes and their clusters.
- [`glab completion`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/completion): Generate shell completion scripts.
- [`glab config`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/config): Set and get CLI settings.
- [`glab deploy-key`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/deploy-key): Manage deploy keys.
- [`glab duo`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/duo): Generate terminal commands from natural language.
- [`glab incident`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/incident): Work with GitLab incidents.
- [`glab issue`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/issue): Work with GitLab issues.
- [`glab iteration`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/iteration): Retrieve iteration information.
- [`glab job`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/job): Work with GitLab CI/CD jobs.
- [`glab label`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/label): Manage labels for your project.
- [`glab mr`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/mr): Create, view, and manage merge requests.
- [`glab release`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/release): Manage GitLab releases.
- [`glab repo`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/repo): Work with GitLab repositories and projects.
- [`glab schedule`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/schedule): Work with GitLab CI/CD schedules.
- [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile): Manage secure files for a project.
- [`glab snippet`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/snippet): Create, view and manage snippets.
- [`glab ssh-key`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/ssh-key): Manage SSH keys registered with your GitLab account.
- [`glab stack`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/stack): Create, manage, and work with stacked diffs.
- [`glab token`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/token): Manage personal, project, or group tokens.
- [`glab user`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/user): Interact with a GitLab user account.
- [`glab variable`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/variable): Manage variables for a GitLab project or group.
- [`glab version`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/version): Show version information for the CLI.

## GitLab Duo for the CLI

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md): Yes
- LLM: Anthropic [Claude 3 Haiku](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-haiku)

{{< /details >}}

{{< history >}}

- Changed to require GitLab Duo add-on in GitLab 17.6 and later.
- Changed to include Premium in GitLab 18.0.

{{< /history >}}

The GitLab CLI includes features powered by [GitLab Duo](../../user/ai_features.md). These include:

- [`glab duo ask`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/duo/ask.md)

To ask questions about `git` commands while you work, type:

- [`glab duo ask`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/duo/ask.md)

The `glab duo ask` command can help you remember a `git` command you forgot,
or provide suggestions on how to run `git` commands to perform other tasks.

## Install the CLI

Installation instructions are available in the `glab`
[`README`](https://gitlab.com/gitlab-org/cli/#installation).

## Authenticate with GitLab

To authenticate with your GitLab account, run `glab auth login`.
`glab` respects tokens set using `GITLAB_TOKEN`.

`glab` also integrates with the [1Password shell plugin](https://developer.1password.com/docs/cli/shell-plugins/gitlab/)
for secure authentication.

## Examples

### Run a CI/CD pipeline with variables from a file

The `glab ci run` command, when run with the `-f` (`--variables-from-string`) flag, uses values stored
in an external file. For example, add this code to your `.gitlab-ci.yml` file
to reference two variables:

```yaml
stages:
  - build

# $EXAMPLE_VARIABLE_1 and $EXAMPLE_VARIABLE_2 are stored in another file
build-job:
  stage: build
  script:
    - echo $EXAMPLE_VARIABLE_1
    - echo $EXAMPLE_VARIABLE_2
    - echo $CI_JOB_ID
```

Then, create a file named `variables.json` to contain those variables:

```json
[
  {
    "key": "EXAMPLE_VARIABLE_1",
    "value": "example value 1"
  },
  {
    "key": "EXAMPLE_VARIABLE_2",
    "value": "example value 2"
  }
]
```

To start a CI/CD pipeline that includes the contents of `variables.json`, run this command, editing
the path to the file as needed:

```shell
$ glab ci run --variables-file /tmp/variables.json`

$ echo $EXAMPLE_VARIABLE_1
example value 1
$ echo $EXAMPLE_VARIABLE_2
example value 2
$ echo $CI_JOB_ID
9811701914
```

### Use the CLI as a Docker credential helper

You can use the CLI as a [Docker credential helper](https://docs.docker.com/reference/cli/docker/login/#credential-helpers)
when pulling images from the GitLab [container registry](../../user/packages/container_registry/_index.md) or the
[container image dependency proxy](../../user/packages/dependency_proxy/_index.md). To configure the credential helper
do the following:

1. Run `glab auth login`.
1. Select the type of GitLab instance to sign in to. If prompted, enter your GitLab hostname.
1. For sign-in method, select `Web`.
1. Enter a comma-separated list of domains used for the container registry and container image proxy.
   When signing in to GitLab.com, default values are provided.
1. After authenticating, run `glab auth configure-docker` to initialize the credential helper in
   your Docker configuration.

## Report issues

Open an issue in the [`gitlab-org/cli` repository](https://gitlab.com/gitlab-org/cli/-/issues/new)
to send us feedback.

## Related topics

- [Install the CLI](https://gitlab.com/gitlab-org/cli/-/blob/main/README.md#installation)
- [Documentation](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source)
- Extension source code in the [`cli`](https://gitlab.com/gitlab-org/cli/) project

## Troubleshooting

### `glab completion` commands fail when using the 1Password shell plugin

The [1Password shell plugin](https://developer.1password.com/docs/cli/shell-plugins/gitlab/)
adds the alias `glab='op plugin run -- glab'`, which can interfere with the `glab completion`
command. If your `glab completion` commands fail, configure your shell to prevent expanding aliases
before performing completions:

- For Zsh, edit your `~/.zshrc` file and add this line:

  ```plaintext
  setopt completealiases
  ```

- For Bash, edit your `~/.bashrc` file and add this line:

  ```plaintext
  complete -F _functionname glab
  ```

For more information, see [issue 122](https://github.com/1Password/shell-plugins/issues/122)
for the 1Password shell plugin.
