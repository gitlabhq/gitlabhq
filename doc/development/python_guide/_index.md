---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Python development guidelines
---

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

## Learning Python

[Resources to get started, examples and tips.](getting_started.md)

## Creating a new Python application

Scaffolding libraries and pipelines for a new codebase.

## Conventions Style Guidelines

[Writing consistent codebases](styleguide.md)

## Code review and maintainership guidelines

[Guidelines on creating MRs and reviewing them](maintainership.md)

## Deploying a Python codebase

[Deploying libraries, utilities and services.](deployment.md)

## Python as part of the Monorepo

[Guide on libraries in the monorepo that use Python](monorepo.md)
