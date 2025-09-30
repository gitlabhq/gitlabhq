---
stage: AI-powered
group: Agent Foundations
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

You should [set up GitLab Duo Agent Platform with the GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/duo_agent_platform.md)
to run local versions of GitLab, Duo Agent Platform Service, and Executor.

This setup can be used as-is with the [publicly available version of the VS Code Extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).

#### Testing Agentic Duo Chat in Web UI

To test Agentic Duo Chat in the Web UI of your local GitLab instance, follow these additional setup steps:

1. [Enable NGINX for your GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/nginx.md).
   A loopback interface and HTTPS are **not** required, only the basic NGINX configuration.
1. Access your GDK at `http://gdk.test:8080`. Your GDK is still available
   at port 3000 but accessing it at port 8080 accesses the application through
   NGINX, which is required for Agentic Duo Chat to work on the web. If you access
   the application at port 3000 and try Agentic Duo Chat, you see an error message:
   `Error: Unable to connect to workflow service. Please try again.`.

### Development Setup for Frontend Components

There is no need to set up the backend components of the Agent Platform to test changes for the Agent Platform UI in the IDE.

A local build of the UI is required if you are making Duo Agent Platform UI changes that you need to view locally. A local build is also required if you want to use a version of the UI that has not been released yet.

Refer to the [GitLab Duo Agent Platform README](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/webview_duo_workflow/README.md) file in the Language Server project to get started with local development of GitLab Duo Agent Platform UI in the IDE.

## Development settings

Each of these settings can be turned on in your user settings in VS Code.

### Change view type

Enable the Duo Agent Platform as a sidepanel instead of fullview. This is going to be the default for public beta.

`"gitlab.featureFlags.duoWorkflowPanel": true,`

### Tool approval

Allow users to get access to tools that require approval such as running terminal commands.

`"gitlab.duo.workflow.toolApproval": true`

## Evaluate flow

### Running evals

To evaluate your local setup, please refer to [Duo Agent Platform Tests](https://gitlab.com/gitlab-org/duo-workflow/testing/duo-workflow-tests) repo.

### Comparing results

Once you finish a evaluation and have a experiment ID from LangSmith, compare results using [this notebook](https://gitlab.com/gitlab-org/duo-workflow/testing/notebooks/-/blob/main/notebooks/compare-swe-bench-evals.ipynb?ref_type=heads) from the [Duo Agent Platform Notebooks](https://gitlab.com/gitlab-org/duo-workflow/testing/notebooks) repo.
