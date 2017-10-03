## Integration tests for GitLab

This directory contains integration tests for GitLab.

It is part of [GitLab QA project](https://gitlab.com/gitlab-org/gitlab-qa).

## What GitLab QA is?

GitLab QA is an integration tests suite for GitLab.

These are black-box and entirely click-driven integration tests you can run
against any existing instance.

## How does it work?

1. When we release a new version of GitLab, we build a Docker images for it.
1. Along with GitLab Docker Images we also build and publish GitLab QA images.
1. GitLab QA project uses these images to execute integration tests.

## How can I use it?

You can use GitLab QA to exercise tests on any live instance! For example, the
follow call would login to the local GitLab instance and run all specs in
`qa/specs/features`:

```
GITLAB_USERNAME='root' GITLAB_PASSWORD='5iveL!fe' bin/qa Test::Instance http://localhost
```

You can also supply a specific tests to run as another parameter. For example, to
test the EE license specs, you can run:

```
EE_LICENSE="<YOUR LICENSE KEY>" GITLAB_USERNAME='root' GITLAB_PASSWORD='5iveL!fe' bin/qa Test::Instance http://localhost qa/ee
```

All [supported environment variables are here](https://gitlab.com/gitlab-org/gitlab-qa#supported-environment-variables).
