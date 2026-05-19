---
stage: AI-powered
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI Expert Agent
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/587460) as a [beta](../../../../policy/development_stages_support.md#beta) in GitLab 18.10
  [with a feature flag](../../../../administration/feature_flags/_index.md) named `foundational_pipeline_authoring_agent`.
  Disabled by default.
- Feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/588564) in GitLab 19.0.

{{< /history >}}

The CI Expert Agent is a specialized agent that helps you create, debug, and
optimize GitLab CI/CD pipelines. It combines:

- Deep expertise in GitLab CI/CD syntax and configuration.
- Knowledge of pipeline optimization strategies and best practices.

Use the CI Expert Agent when you need help with:

- Pipeline creation: Generate `.gitlab-ci.yml` configurations from scratch based on your project requirements.
- Syntax explanation: Understand CI/CD keywords and configuration options.
- Debugging: Analyze job logs and troubleshoot pipeline failures.
- Optimization: Improve pipeline performance through caching, parallelization, and using the `needs` keyword to let jobs start earlier.
- Implementing proper use of CI/CD keywords, including `rules`, `artifacts`, `services`, and `environments`.

## Access the CI Expert Agent

Prerequisites:

- Foundational agents must be [turned on](_index.md#turn-foundational-agents-on-or-off).

To access the CI Expert Agent:

1. On the top bar, select **Search or go to** and find your project.
1. On the GitLab Duo sidebar, select **Add new chat**
   ({{< icon name="pencil-square" >}}).
1. From the dropdown list, select **CI Expert**.

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your screen.
1. Enter your CI/CD-related question or request. To get the best results from your request:

   - Describe your project type and technology stack.
   - Share your existing `.gitlab-ci.yml` if you have one.
   - Specify your goals. For example, faster builds, deployment to Kubernetes, or running tests in parallel.

### Example prompts

- "Create a CI/CD pipeline for my Node.js project with testing and Docker build."
- "How do I cache dependencies to speed up my builds?"
- "Add a deployment stage to my pipeline for Kubernetes."
- "What's the difference between `cache` and `artifacts`?"
- "Help me set up parallel testing for my test suite."
- "How do I use `needs` to make jobs start earlier?"
- "Explain what this CI/CD configuration does: (paste configuration)"
- "How do I set up a multi-project pipeline?"
- "What's the best way to handle secrets in my pipeline?"
- "Help me optimize my pipeline to reduce build times."
- "How do I run jobs only on merge requests?"
- "Create a `.gitlab-ci.yml` for my Python project with pytest and linting."
- "How do I use artifacts to pass data between jobs?"
