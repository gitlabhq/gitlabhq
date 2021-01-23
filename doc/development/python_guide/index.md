---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Python Development Guidelines

GitLab requires Python as a dependency for [reStructuredText](https://docutils.sourceforge.io/rst.html)
markup rendering.

As of GitLab 11.10, we require Python 3.

## Installation

There are several ways of installing Python on your system. To be able to use the same version we use in production,
we suggest you use [`pyenv`](https://github.com/pyenv/pyenv). It works and behaves similarly to its counterpart in the
Ruby world: [`rbenv`](https://github.com/rbenv/rbenv).

### macOS

To install `pyenv` on macOS, you can use [Homebrew](https://brew.sh/) with:

```shell
brew install pyenv
```

### Linux

To install `pyenv` on Linux, you can run the command below:

```shell
curl "https://pyenv.run" | bash
```

Alternatively, you may find `pyenv` available as a system package via your distribution's package manager.

You can read more about it in [the `pyenv` prerequisites](https://github.com/pyenv/pyenv-installer#prerequisites).

### Shell integration

`Pyenv` installation adds required changes to Bash. If you use a different shell,
check for any additional steps required for it.

For Fish, you can install a plugin for [Fisher](https://github.com/jorgebucaran/fisher):

```shell
fisher add fisherman/pyenv
```

Or for [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish):

```shell
omf install pyenv
```

## Dependency management

While GitLab doesn't directly contain any Python scripts, because we depend on Python to render
[reStructuredText](https://docutils.sourceforge.io/rst.html) markup, we need to keep track on dependencies
on the main project level, so we can run that on our development machines.

Recently, an equivalent to the `Gemfile` and the [Bundler](https://bundler.io/) project has been introduced to Python:
`Pipfile` and [Pipenv](https://pipenv.readthedocs.io/en/latest/).

A `Pipfile` with the dependencies now exists in the root folder. To install them, run:

```shell
pipenv install
```

Running this command installs both the required Python version as well as required pip dependencies.

## Use instructions

To run any Python code under the Pipenv environment, you need to first start a `virtualenv` based on the dependencies
of the application. With Pipenv, this is a simple as running:

```shell
pipenv shell
```

After running that command, you can run GitLab on the same shell and it uses the Python and dependencies
installed from the `pipenv install` command.
