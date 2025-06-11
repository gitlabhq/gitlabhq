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

- [`glab alias`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/alias)
- [`glab api`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/api)
- [`glab auth`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/auth)
- [`glab changelog`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/changelog)
- [`glab check-update`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/check-update)
- [`glab ci`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/ci)
- [`glab cluster`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/cluster)
- [`glab completion`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/completion)
- [`glab config`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/config)
- [`glab deploy-key`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/deploy-key)
- [`glab duo`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/duo)
- [`glab incident`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/incident)
- [`glab issue`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/issue)
- [`glab iteration`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/iteration)
- [`glab job`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/job)
- [`glab label`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/label)
- [`glab mr`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/mr)
- [`glab release`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/release)
- [`glab repo`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/repo)
- [`glab schedule`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/schedule)
- [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile)
- [`glab snippet`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/snippet)
- [`glab ssh-key`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/ssh-key)
- [`glab stack`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/stack)
- [`glab token`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/token)
- [`glab user`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/user)
- [`glab variable`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/variable)
- [`glab version`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/version)

## GitLab Duo for the CLI

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
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
