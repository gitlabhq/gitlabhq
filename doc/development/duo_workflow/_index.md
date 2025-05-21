---
stage: AI-powered
group: Duo Workflow
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Development of GitLab Duo Workflow
---

How to set up the local development environment to run [GitLab Duo Workflow](../../user/duo_workflow/_index.md).

## Prerequisites

- [GitLab Ultimate license](https://handbook.gitlab.com/handbook/engineering/developer-onboarding/#working-on-gitlab-ee-developer-licenses)
- [Vertex access](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_ai_gateway.md#use-the-existing-project): You need access to the `ai-enablement-dev-69497ba7` project in GCP because GDK by default uses Anthropic hosted on Vertex. Access to this project should be available to all engineers at GitLab.
  - If you do not have Vertex access for any reason, you should unset `DUO_WORKFLOW__VERTEX_PROJECT_ID` in the Duo Workflow Service and set `ANTHROPIC_API_KEY` to a regular Anthropic API key
- Various settings and feature flags, which are enabled for you by the [GDK setup script](#development-setup-for-backend-components)

## Set up local development for Workflow

Workflow consists of four separate services:

1. [GitLab instance](https://gitlab.com/gitlab-org/gitlab/)
1. GitLab Duo Workflow Service, which is part of the [GitLab AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/duo_workflow_service.md?ref_type=heads)
1. [GitLab Duo Workflow Executor](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor/)
1. [GitLab Duo Workflow Webview](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/webview_duo_workflow/README.md)

### Development Setup for Backend Components

You should [set up GitLab Duo Workflow with the GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/duo_workflow.md)
to run local versions of GitLab, Duo Workflow Service, and Executor.

This setup can be used as-is with the [publicly available version of the VS Code Extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).

### Development Setup for Frontend Components

There is no need to set up the backend components of Duo Workflow to test changes for the GitLab Duo Workflow UI.

A local build of the UI is required if you are making Duo Workflow UI changes that you need to view locally. A local build is also required if you want to use a version of the UI that has not been released yet.

Refer to the [GitLab Duo Workflow README](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/webview_duo_workflow/README.md) file in the Language Server project to get started with local development of GitLab Duo Workflow UI.
