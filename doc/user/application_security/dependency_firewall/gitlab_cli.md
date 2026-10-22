---
stage: Security Risk Management
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Use the GitLab CLI with the dependency firewall
description: Run a package manager through the dependency firewall with the glab df commands.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

The [GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md) runs your package manager
through the dependency firewall. Prefix any supported package manager command with
`glab dependency-firewall`, or its shorter alias `glab df`:

```shell
glab df npm install
glab df pip install requests
glab df maven verify
```

There is nothing to configure. The CLI reads the project from your Git remote, authenticates
with your existing `glab` credentials, and uses the registry your package manager is already
configured to use.

## Prerequisites

- Install the [GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md).
- Authenticate with `glab auth login`.
- Run the command from a Git checkout whose remote points at the GitLab project the policies
  apply to.
- Have the package manager binary on your `PATH`.

## How the commands work

Each `glab df` command runs the package manager binary and forwards every argument to it
verbatim. While the manager runs, the CLI:

1. Starts a local inspection proxy and routes the package manager HTTPS traffic through it.
1. Reads each package name and version the manager requests.
1. Asks GitLab to evaluate that package against the policies for your project.
1. Refuses blocked packages with a `403 Forbidden` response, and lets allowed and warned
   packages through.
1. Writes the blocked and warned packages to `.gitlab/df/ci-log.json` and prints a summary.
1. Exits with the package manager exit code.

The CLI does not modify your `.npmrc`, `.yarnrc.yml`, `pip.conf`, `settings.xml`, `~/.gemrc`, or
any other registry configuration. It inspects the traffic in between instead.

Evaluation results are cached for the lifetime of a single run, so a package that appears many
times in a dependency tree is evaluated once.

The command exits with the following codes:

| Exit code | Meaning |
|-----------|---------|
| The package manager exit code | The package manager ran and exited. |
| `1`       | The package manager was not found on your `PATH` or could not start. The CLI prints an error. |
| `130`     | The run was interrupted, for example with <kbd>Control</kbd>+<kbd>C</kbd>. |

The CLI writes `.gitlab/df/ci-log.json` into the working directory on every run, including local
runs, so the file appears as an untracked file in your repository. Add `.gitlab/df/` to your
`.gitignore` file.

## Read the run summary

After the package manager exits, the CLI prints a table of every package the firewall warned on
or blocked:

```plaintext
╭────────────────────────────────────────────────────────────────────╮
│ ✖  GitLab Dependency Firewall                                      │
│ 1 blocked, 1 warning                                               │
├────────────────────────────────────────────────────────────────────┤
│    PACKAGE   VERSION  REASON                                       │
│ ✖  left-pad    1.3.0  Package 'left-pad' violates 'no-gpl' policy  │
│ ▲  lodash    4.17.15  Package 'lodash' violates 'high-risk' policy │
╰────────────────────────────────────────────────────────────────────╯
```

A `✖` marks a blocked package and a `▲` marks a warned package.

A run with at least one blocked package prints the summary to standard error. A run with only
warnings prints it to standard output. The CLI never records allowed packages, so a run with no
warnings or blocks prints no summary.

## Use the firewall in CI/CD

Prefix the package manager command in your job script. The job fails when the package manager
fails, because the CLI propagates its exit code:

```yaml
install:
  variables:
    GLAB_ENABLE_CI_AUTOLOGIN: "true"
  script:
    - glab df npm ci
```

The CLI signs in with the CI/CD job token only when the `GLAB_ENABLE_CI_AUTOLOGIN` CI/CD
variable is `true`. The default is `false`. The CLI also requires `GITLAB_CI=true`, which GitLab
sets in every job. With the variable set, no other credentials are needed.

The job token can evaluate packages for its own project only. GitLab refuses a token from
another project. The user who triggered the job must have at least the Reporter role on the
project.

To report on firewall activity as a separate step, use `glab df ci-summary`. It reads
`.gitlab/df/ci-log.json` and prints the blocked and warned packages recorded by every `glab df`
run in that directory:

```yaml
install:
  variables:
    GLAB_ENABLE_CI_AUTOLOGIN: "true"
  script:
    - glab df npm ci
    - glab df pip install -r requirements.txt
  after_script:
    - glab df ci-summary
```

`glab df ci-summary` uses the following exit codes:

| Exit code | Meaning |
|-----------|---------|
| `0`       | No blocked packages in the log. |
| `1`       | The log could not be read. |
| `3`       | At least one package in the log was blocked. |

Run `glab df ci-summary` from the same directory as the `glab df` commands that wrote the log.
Otherwise it finds no log, reports nothing blocked, and exits with `0`.

Entries accumulate across runs and the CLI never clears them. A block from an earlier run keeps
`glab df ci-summary` exiting with `3` until you delete `.gitlab/df/ci-log.json`. If the file is
unreadable, the CLI leaves it in place and does not overwrite it, and `glab df ci-summary` exits
with `1`.

Do not restore the package manager cache between jobs if you want every package to be
evaluated. Packages restored from a cache are [not evaluated](_index.md#restrictions).

## Check a single package

Use `glab df package` to check one package against the policies for your project. It does not run
a package manager, and no package manager needs to be installed. Like the other commands, it
resolves the project from your Git remote.

Pass a package URL (PURL) that includes a version. The supported PURL types are `npm`, `pypi`,
`maven`, and `gem`:

```shell
glab df package pkg:npm/left-pad@1.3.0
glab df package pkg:pypi/requests@2.31.0
glab df package pkg:maven/org.slf4j/slf4j-api@2.0.13
glab df package pkg:gem/rails@7.1.3
```

`glab df package` uses the following exit codes:

| Exit code | Meaning |
|-----------|---------|
| `0`       | The package is allowed or warned. |
| `1`       | The CLI is misconfigured, or a transport error occurred. |
| `3`       | The package is blocked. |

The command does not write to `.gitlab/df/ci-log.json`, so `glab df ci-summary` does not include
its result.

## When GitLab can't evaluate a package

The CLI handles an evaluation that cannot complete in one of two ways.

### The CLI blocks the package

If the evaluation request fails, the CLI blocks the package. A request fails because of a
network error, a timeout after 60 seconds, a server error (`503`), rate limiting (`429`), or a
permission error (`403`), for example when you do not have the Reporter role. The reason in the
summary starts with `policy check failed:`.

The CLI retries a failed check the next time the package is requested in the same run.

### The CLI allows every package

If GitLab responds that the firewall is not evaluating the project, the CLI allows every package
for the rest of the run. This happens when the firewall is turned off, or when GitLab cannot find
the project or your token cannot access it. The CLI prints one line to standard error that starts
with `dependency firewall not evaluating`.

A mistyped Git remote or a token that cannot access the project therefore allows every
package. Check your output for that line.

## Projects without the firewall

When the firewall is not turned on for a project, `glab df` commands run the package manager as
usual and evaluate nothing. The CLI prints a line that starts with
`dependency firewall not evaluating` to standard error. You can use the same commands in every
project, whether or not a policy applies.
