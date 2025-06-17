---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Shell scripting standards and style guidelines
---

GitLab consists of many various services and sub-projects. The majority of
their backend code is written in [Ruby](https://www.ruby-lang.org) and
[Go](https://go.dev/). However, some of them use shell scripts for
automation of routine system administration tasks like deployment,
installation, etc. It's being done either for historical reasons or as an effort
to minimize the dependencies, for instance, for Docker images.

This page aims to define and organize our shell scripting guidelines,
based on our various experiences. All shell scripts across GitLab project
should be eventually harmonized with this guide. If there are any per-project
deviations from this guide, they should be described in the
`README.md` or `PROCESS.md` file for such a project.

## Avoid using shell scripts

{{< alert type="warning" >}}

This is a must-read section.

{{< /alert >}}

Having said all of the above, we recommend staying away from shell scripts
as much as possible. A language like Ruby or Python (if required for
consistency with codebases that we leverage) is almost always a better choice.
The high-level interpreted languages have more readable syntax, offer much more
mature capabilities for unit-testing, linting, and error reporting.

Use shell scripts only if there's a strong restriction on project's
dependencies size or any other requirements that are more important
in a particular case.

## Scope of this guide

According to the [GitLab installation requirements](../../install/requirements.md),
this guide covers only those shells that are used by
[supported Linux distributions](../../administration/package_information/supported_os.md),
that is:

- [POSIX Shell](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [Bash](https://www.gnu.org/software/bash/)

## Shell language choice

- When you need to reduce the dependencies list, use what's provided by the environment. For example, for Docker images it's `sh` from `alpine` which is the base image for most of our tool images.
- Everywhere else, use `bash` if possible. It's more powerful than `sh` but still a widespread shell.

## Code style and format

This section describes the tools that should be made a mandatory part of
a project's CI pipeline if it contains shell scripts. These tools
automate shell code formatting, checking for errors or vulnerabilities, etc.

### Linting

We're using the [ShellCheck](https://www.shellcheck.net/) utility in its default configuration to lint our
shell scripts.

All projects with shell scripts should use this GitLab CI/CD job:

```yaml
shell check:
  image: koalaman/shellcheck-alpine:stable
  stage: test
  before_script:
    - shellcheck --version
  script:
    - shellcheck scripts/**/*.sh  # path to your shell scripts
```

{{< alert type="note" >}}

By default, ShellCheck uses the [shell detection](https://github.com/koalaman/shellcheck/wiki/SC2148#rationale)
to determine the shell dialect in use. If the shell file is out of your control and ShellCheck cannot
detect the dialect, use `-s` flag to specify it: `-s sh` or `-s bash`.

{{< /alert >}}

### Formatting

It's recommended to use the [shfmt](https://github.com/mvdan/sh#shfmt) tool to maintain consistent formatting.
We format shell scripts according to the [Google Shell Style Guide](https://google.github.io/styleguide/shell.xml),
so the following `shfmt` invocation should be applied to the project's script files:

```shell
shfmt -i 2 -ci -w scripts/**/*.sh
```

In addition to the [Linting](#linting) GitLab CI/CD job, all projects with shell scripts should also
use this job:

```yaml
shfmt:
  image: mvdan/shfmt:v3.2.0-alpine
  stage: test
  before_script:
    - shfmt -version
  script:
    - shfmt -i 2 -ci -d scripts  # path to your shell scripts
```

{{< alert type="note" >}}

By default, shfmt uses the [shell detection](https://github.com/mvdan/sh#shfmt) similar to one of ShellCheck
and ignore files starting with a period. To override this, use `-ln` flag to specify the shell dialect:
`-ln posix` or `-ln bash`.

{{< /alert >}}

## Testing

{{< alert type="note" >}}

This is a work in progress.

{{< /alert >}}

It is an [ongoing effort](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/64016) to evaluate different tools for the
automated testing of shell scripts (like [BATS](https://github.com/bats-core/bats-core)).

## Code Review

The code review should be performed according to:

- [ShellCheck Checks list](https://github.com/koalaman/shellcheck/wiki/Checks)
- [Google Shell Style Guide](https://google.github.io/styleguide/shell.xml)
- [Shfmt formatting caveats](https://github.com/mvdan/sh#caveats)

However, the recommended course of action is to use the aforementioned
tools and address reported offenses. This should eliminate the need
for code review.

---

[Return to Development documentation](../_index.md).
