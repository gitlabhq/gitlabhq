---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Python development guidelines

This document describes conventions and practices we adopt at GitLab when developing Python code. While GitLab is built
primarily on Ruby on Rails, we use Python when needed to leverage the ecosystem.

Some examples of Python in our codebase:

- [AI gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/tree/main/ai_gateway)
- [Duo Workflow Service](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-service)
- [Evaluation Framework](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library)
- [CloudConnector Python library](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/tree/main/src/python)

## Design principles

- Tooling should help contributors achieve their goals, both on short and long term.
- A developer familiar with a Python codebase in GitLab should feel familiar with any other Python codebase at GitLab.
- This documentation should support all contributors, regardless of their goals and incentives: from Python experts to one-off contributors.
- We strive to follow external guidelines, but if needed we will choose conventions that better support GitLab contributors.

## When should I consider Python for development

Ruby should always be the first choice for development at GitLab, as we have a larger community, better support, and easier deployment. However, there are occasions where using Python is worth breaking the pattern. For example,
when working with AI and ML, most of the open source uses Python, and using Ruby would require building and maintaining
large codebases.

## Creating a new Python application

Scaffolding, libraries and pipelines for a new codebase.

## Conventions Style Guidelines

Writing consistent codebases.

## Contributing to a Python codebase

Resources to get started, examples and tips.

## Code review and maintainership guidelines

**Note**: this section is currently in development. You can contribute or track its progress in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/16090)

GitLab standard [code review guidelines](../code_review.md#approval-guidelines) apply to Python projects as well.

### How to find a reviewer

This section explains how to integrate your project with [reviewer roulette](../code_review.md#reviewer-roulette)
and other resources to find reviewers with Python expertise.

[Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/514318).

### How to find a project to review

[Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/511513).

### Maintainer responsibilities

In addition to code reviews, maintainers are responsible for guiding architectural decisions and monitoring and adopting relevant engineering practices introduced in GitLab.com into their Python projects. This helps to ensure Python projects are consistent and aligned with company standards. Maintaining consistency simplifies transitions between GitLab.com and Python projects while reducing context switching overhead.

**Technical prerequisites for Maintainers:**

- Strong experience with the Python frameworks used in the specific project. Commonly used frameworks include: [FastAPI](https://fastapi.tiangolo.com/) and [Pydantic](https://docs.pydantic.dev/latest/), etc.
- Proficiency with Python testing frameworks such as `pytest`, including advanced testing strategies (for example, mocking, integration tests, and test-driven development).
- Understanding of backwards compatibility considerations ([Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/514689)).

**Code review objectives:**

- Verify and confirm changes adheres to style guide ([Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/506689)) and existing patterns in the project.
- Where applicable, ensure test coverage is added for the changes introduced in the MR.
- Review for performance implications.
- Check for security vulnerabilities.
- Assess code change impact on existing systems.
- Verify that the MR has the correct [MR type label](../labels/index.md#type-labels) and is assigned to the current milestone.

**Additional responsibilities:**

- Maintain relevant documentation accuracy and completeness.
- Monitor and update package dependencies as necessary.
- Mentor other engineers on Python best practices.
- Evaluate and propose new tools and libraries.
- Monitor performance and propose optimizations.
- Ensure security standards are maintained.
- Ensure the project is consistent and aligned with GitLab standards by regularly monitoring and adopting relevant engineering practices introduced in GitLab.com.

### How to become a maintainer

Each project has its own process and maintainership program. We recommend reviewing the following guideline:

[Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/514316).

### Code review best practices

When writing and reviewing code, follow our Style Guides. Code authors and reviewers are encouraged to pay attention
to these areas:

[Work item](https://gitlab.com/gitlab-org/gitlab/-/issues/507548).

## Deploying a Python codebase

Deploying libraries, utilities and services.

## Python as part of the Monorepo

GitLab requires Python as a dependency for [reStructuredText](https://docutils.sourceforge.io/rst.html) markup rendering. It requires Python 3.

### Installation

There are several ways of installing Python on your system. To be able to use the same version we use in production,
we suggest you use [`pyenv`](https://github.com/pyenv/pyenv). It works and behaves similarly to its counterpart in the
Ruby world: [`rbenv`](https://github.com/rbenv/rbenv).

#### macOS

To install `pyenv` on macOS, you can use [Homebrew](https://brew.sh/) with:

```shell
brew install pyenv
```

#### Windows

`pyenv` does not officially support Windows and does not work in Windows outside the Windows Subsystem for Linux. If you are a Windows user, you can use `pyenv-win`.

To install `pyenv-win` on Windows, run the following PowerShell command:

```shell
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
```

[Learn more about `pyenv-win`](https://github.com/pyenv-win/pyenv-win).

#### Linux

To install `pyenv` on Linux, you can run the command below:

```shell
curl "https://pyenv.run" | bash
```

Alternatively, you may find `pyenv` available as a system package via your distribution's package manager.

You can read more about it in [the `pyenv` prerequisites](https://github.com/pyenv/pyenv-installer#prerequisites).

#### Shell integration

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

#### Dependency management

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

#### Use instructions

To run any Python code under the Pipenv environment, you need to first start a `virtualenv` based on the dependencies
of the application. With Pipenv, this is a simple as running:

```shell
pipenv shell
```

After running that command, you can run GitLab on the same shell and it uses the Python and dependencies
installed from the `pipenv install` command.

## Learning resources

If you are new to Python or looking to refresh your knowledge, this section provides various materials for
learning the language.

1. **[Python Cheatsheet](https://www.pythoncheatsheet.org)**
A comprehensive reference covering essential Python syntax, built-in functions, and useful libraries.
This is ideal for both beginners and experienced users who want a quick, organized summary of Python's key features.

1. **[A Whirlwind Tour of Python (Jupyter Notebook)](https://github.com/jakevdp/WhirlwindTourOfPython)**
A fast-paced introduction to Python fundamentals, tailored especially for data science practitioners but works well for everyone who wants to get just the basic understanding of the language.
This is a Jupiter Notebook which makes this guide an interactive resource as well as a good introduction to Jupiter Notebook itself.

1. **[100-page Python Intro](https://learnbyexample.github.io/100_page_python_intro)**
Brief guide provides a straightforward introduction to Python, covering all the essentials needed to start programming effectively. It’s a beginner-friendly option that covers everything from syntax to debugging and testing.

1. **[Learn X in Y Minutes: Python](https://learnxinyminutes.com/docs/python)**
A very brief, high-level introduction cuts directly to the core syntax and features of Python, making it a valuable quick start for developers transitioning to Python.

1. **[Exercism Python Track](https://exercism.io/tracks/python)**
   Use Exercism's Python track as a foundation for learning Python concepts and best practices. Exercism provides hands-on practice with mentoring support, making it an excellent resource for mastering Python through coding exercises and feedback.

When building Python APIs, we use FastAPI and Pydantic. To get started with building and reviewing these technologies, refer to the following resources:

1. **[FastAPI Documentation](https://fastapi.tiangolo.com/)**
   FastAPI is a modern web framework for building APIs with Python. This resource will help you learn how to create fast and efficient web applications and APIs. FastAPI is especially useful for building Python applications with high performance and scalability.

1. **[Pydantic Documentation](https://pydantic-docs.helpmanual.io/)**
   Pydantic is a Python library for data validation and settings management using Python type annotations. Learn how to integrate Pydantic into your Python projects for easier data validation and management, particularly when working with FastAPI.

We use pytest for testing Python code. To learn more about writing and running tests with pytest, refer to the following resources:

1. **[pytest Documentation](https://docs.pytest.org/en/stable/)**
   pytest is a popular testing framework for Python that makes it easy to write simple and scalable tests. This resource provides comprehensive documentation on how to write and run tests using pytest, including fixtures, plugins, and test discovery.

1. **[Python Testing with pytest (Book)](https://pragprog.com/titles/bopytest2/python-testing-with-pytest-second-edition/)**
   This book is a comprehensive guide to testing Python code with pytest. It covers everything from the basics of writing tests to advanced topics like fixtures, plugins, and test organization.
