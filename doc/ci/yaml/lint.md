---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Validate GitLab CI/CD configuration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the CI Lint tool to check the validity of GitLab CI/CD configuration.
You can validate the syntax from a `.gitlab-ci.yml` file or any other sample CI/CD configuration.
This tool checks for syntax and logic errors, and can simulate pipeline
creation to try to find more complicated configuration problems.

If you use the [pipeline editor](../pipeline_editor/_index.md), it verifies configuration
syntax automatically.

If you use VS Code, you can validate your CI/CD configuration with the
[GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/_index.md).

## Check CI/CD syntax

The CI lint tool checks the syntax of GitLab CI/CD configuration, including
configuration added with the [`includes` keyword](_index.md#include).

To check CI/CD configuration with the CI lint tool:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline editor**.
1. Select the **Validate** tab.
1. Select **Lint CI/CD sample**.
1. Paste a copy of the CI/CD configuration you want to check into the text box.
1. Select **Validate**.

## Simulate a pipeline

You can simulate the creation of a GitLab CI/CD pipeline to find more complicated issues,
including problems with [`needs`](_index.md#needs) and [`rules`](_index.md#rules)
configuration. A simulation runs as a Git `push` event on the default branch.

Prerequisites:

- You must have [permissions](../../user/permissions.md#project-members-permissions)
  to create pipelines on this branch to validate with a simulation.

To simulate a pipeline:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline editor**.
1. Select the **Validate** tab.
1. Select **Lint CI/CD sample**.
1. Paste a copy of the CI/CD configuration you want to check into the text box.
1. Select **Simulate pipeline creation for the default branch**.
1. Select **Validate**.
