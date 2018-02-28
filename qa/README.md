# GitLab QA - Integration tests for GitLab

This directory contains integration tests for GitLab.

It is part of the [GitLab QA project](https://gitlab.com/gitlab-org/gitlab-qa).

## What is it?

GitLab QA is an integration tests suite for GitLab.

These are black-box and entirely click-driven integration tests you can run
against any existing instance.

## How does it work?

1. When we release a new version of GitLab, we build a Docker images for it.
1. Along with GitLab Docker Images we also build and publish GitLab QA images.
1. GitLab QA project uses these images to execute integration tests.

## How can I use it?

You can use GitLab QA to exercise tests on any live instance! For example, the
following call would login to a local [GDK] instance and run all specs in
`qa/specs/features`:

```
bin/qa Test::Instance http://localhost:3000
```

### Running specific tests

You can also supply specific tests to run as another parameter. For example, to
test the EE license specs, you can run:

```
EE_LICENSE="<YOUR LICENSE KEY>" bin/qa Test::Instance http://localhost qa/specs/features/ee
```

Since the arguments would be passed to `rspec`, you could use all `rspec`
options there. For example, passing `--backtrace` and also line number:

```
bin/qa Test::Instance http://localhost qa/specs/features/login/standard_spec.rb:3 --backtrace
```

### Overriding the authenticated user

Unless told otherwise, the QA tests will run as the default `root` user seeded
by the GDK.

If you need to authenticate as a different user, you can provide the
`GITLAB_USERNAME` and `GITLAB_PASSWORD` environment variables:

```
GITLAB_USERNAME=jsmith GITLAB_PASSWORD=password bin/qa Test::Instance https://gitlab.example.com
```

All [supported environment variables are here](https://gitlab.com/gitlab-org/gitlab-qa#supported-environment-variables).

[GDK]: https://gitlab.com/gitlab-org/gitlab-development-kit/
