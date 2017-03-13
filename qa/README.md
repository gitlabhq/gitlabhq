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
