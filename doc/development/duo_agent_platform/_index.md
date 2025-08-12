---
stage: AI-powered
group: Duo Workflow
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Development of GitLab Duo Agent Platform
---

{{< history >}}

- [Name changed](https://gitlab.com/gitlab-org/gitlab/-/issues/551382) from `Workflow` to `Agent Platform` in GitLab 18.2.

{{< /history >}}

How to set up the local development environment to run [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md).

## Prerequisites

- [GitLab Ultimate license](https://handbook.gitlab.com/handbook/engineering/developer-onboarding/#working-on-gitlab-ee-developer-licenses)
- [Vertex access](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/gitlab_ai_gateway.md#use-the-existing-project): You need access to the `ai-enablement-dev-69497ba7` project in GCP because GDK by default uses Anthropic hosted on Vertex. Access to this project should be available to all engineers at GitLab.
  - If you do not have Vertex access for any reason, you should unset `DUO_WORKFLOW__VERTEX_PROJECT_ID` in the Duo Agent Platform Service and set `ANTHROPIC_API_KEY` to a regular Anthropic API key
- Various settings and feature flags, which are enabled for you by the [GDK setup script](#development-setup-for-backend-components)

## Set up local development for Agent Platform

Agent Platform consists of four separate services:

1. [GitLab instance](https://gitlab.com/gitlab-org/gitlab/)
1. GitLab Duo Agent Platform Service, which is part of [GitLab AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/)
1. [GitLab Duo Agent Platform Executor](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor/)
1. [GitLab Duo Agent Platform Webview](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/webview_duo_workflow/README.md)

### Development Setup for Backend Components

You should [set up GitLab Duo Agent Platform with the GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/duo_workflow.md)
to run local versions of GitLab, Duo Agent Platform Service, and Executor.

This setup can be used as-is with the [publicly available version of the VS Code Extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).

### Development Setup for Frontend Components

There is no need to set up the backend components of the Agent Platform to test changes for the Agent Platform UI in the IDE.

A local build of the UI is required if you are making Duo Agent Platform UI changes that you need to view locally. A local build is also required if you want to use a version of the UI that has not been released yet.

Refer to the [GitLab Duo Agent Platform README](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/webview_duo_workflow/README.md) file in the Language Server project to get started with local development of GitLab Duo Agent Platform UI in the IDE.

## Development settings

Each of these settings can be turned on in your user settings in VS Code.

### Change view type

Enable the Duo Agent Platform as a sidepanel instead of fullview. This is going to be the default for public beta.

`"gitlab.featureFlags.duoWorkflowPanel": true,`

### Executor type

Allow to define which Duo Agent Platform executor is selected. Accepts:

- `shell` - Current default, runs the go binary directly on the user's machine
- `docker` - Runs the go binary inside a Docker container (deprecated)
- `node` - Runs a nodeJs/TypeScript executor directly inside the language server. Expected to become the default.

`"gitlab.duo.workflow.executor": "node",`

### Agent Platform flow

Experimental settings that allow Duo Agent Platform flow to be swapped. Includes:

- `software_development` - default
- `chat` - used by agentic chat
- `search_and_replace` - Used to scan large number of files and replace results with specific instructions

`"gitlab.duo.workflow.graph": "software_development",`

### Tool approval

Allow users to get access to tools that require approval such as running terminal commands.

`"gitlab.duo.workflow.toolApproval": true`

## Evaluate flow

### Running evals

To evaluate your local setup, please refer to [Duo Agent Platform Tests](https://gitlab.com/gitlab-org/duo-workflow/testing/duo-workflow-tests) repo.

### Comparing results

Once you finish a evaluation and have a experiment ID from LangSmith, compare results using [this notebook](https://gitlab.com/gitlab-org/duo-workflow/testing/notebooks/-/blob/main/notebooks/compare-swe-bench-evals.ipynb?ref_type=heads) from the [Duo Agent Platform Notebooks](https://gitlab.com/gitlab-org/duo-workflow/testing/notebooks) repo.
