# Python Development Guidelines

GitLab requires Python as a dependency for [reStructuredText](http://docutils.sourceforge.net/rst.html)
markup rendering.

As of GitLab 11.10, we require Python 3.

## Installation

There are several ways of installing python on your system. To be able to use the same version we use in production,
we suggest you use [pyenv](https://github.com/pyenv/pyenv). It works and behave similar to its counterpart in the
ruby world: [rbenv](https://github.com/rbenv/rbenv).

### macOS

To install `pyenv` on macOS, you can use [Homebrew](https://brew.sh/) with:

```bash
brew install pyenv
```

### Linux

To install `pyenv` on Linux, you can run the command below:

```bash
curl https://pyenv.run | bash
```

Alternatively, you may find `pypenv` available as a system package via your distro package manager.

You can read more about it in: <https://github.com/pyenv/pyenv-installer#prerequisites>.

### Shell integration

Pyenv installation will add required changes to Bash. If you use a different shell,
check for any additional steps required for it.

For Fish, you can install a plugin for [Fisher](https://github.com/jorgebucaran/fisher):

```bash
fisher add fisherman/pyenv
```

Or for [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish):

```bash
omf install pyenv
```

## Dependency management

While GitLab doesn't directly contain any Python scripts, because we depend on Python to render
[reStructuredText](http://docutils.sourceforge.net/rst.html) markup, we need to keep track on dependencies
on the main project level, so we can run that on our development machines.

Recently, an equivalent to the `Gemfile` and the [Bundler](https://bundler.io/) project has been introduced to Python:
`Pipfile` and [Pipenv](https://pipenv.readthedocs.io/en/latest/).

You will now find a `Pipfile` with the dependencies in the root folder. To install them, run:

```bash
pipenv install
```

Running this command will install both the required Python version as well as required pip dependencies.

## Use instructions

To run any python code under the Pipenv environment, you need to first start a `virtualenv` based on the dependencies
of the application. With Pipenv, this is a simple as running:

```bash
pipenv shell
```

After running that command, you can run GitLab on the same shell and it will be using the Python and dependencies
installed from the `pipenv install` command.
