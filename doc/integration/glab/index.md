---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab CLI - `glab`

GLab is an open source GitLab CLI tool. It brings GitLab to your terminal:
next to where you are already working with Git and your code, without
switching between windows and browser tabs.

- Work with issues.
- Work with merge requests.
- Watch running pipelines directly from your CLI.

![command example](img/glabgettingstarted.gif)

The GitLab CLI uses commands structured like `glab <command> <subcommand> [flags]`
to perform many of the actions you normally do from the GitLab user interface:

```shell
# Sign in
glab auth login --stdin < token.txt

# View a list of issues
glab issue list

# Create merge request for issue 123
glab mr for 123

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

- `glab alias`
- `glab api`
- `glab auth`
- `glab ci`
- `glab issue`
- `glab label`
- `glab mr`
- `glab project`
- `glab release`
- `glab snippet`
- `glab ssh-key`
- `glab user`
- `glab variable`

## Install the CLI

Installation instructions are available in the GLab
[`README`](https://gitlab.com/gitlab-org/cli/#installation).

## Authenticate with GitLab

To authenticate with your GitLab account, run `glab auth login`.
`glab` respects tokens set using `GITLAB_TOKEN`.

## Report issues

Open an issue in the [`gitlab-org/cli` repository](https://gitlab.com/gitlab-org/cli/issues/new)
to send us feedback.

## Related topics

- [Install the CLI](https://gitlab.com/gitlab-org/cli/-/blob/main/README.md#installation)
- [Documentation](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source)
- The extension source code is available in the
  [`cli`](https://gitlab.com/gitlab-org/cli/) project.

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
