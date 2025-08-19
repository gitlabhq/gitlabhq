---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure where flows run
---

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/477166) in GitLab 18.3.

{{< /history >}}

Flows use agents to execute tasks.

- Flows executed from the GitLab UI use CI/CD.
- Flows executed in an IDE run locally.

## Change the default image for CI/CD

By default, all flows executed with CI/CD use a standard Docker image provided by GitLab.
However, you can change the Docker image and specify your own instead.
Your own image can be useful for complex projects that require specific dependencies or tools.

To change the default Docker image:

1. In your project's repository, create a `.gitlab/duo/` folder if it doesn't exist.
1. In the folder, create a configuration file `agent-config.yml`.
1. In the file, add the following configuration:

   ```yaml
   image: YOUR_DOCKER_IMAGE
   ```

   For example:

   ```yaml
   image: python:3.11-slim
   ```

   Or for a Node.js project:

   ```yaml
   image: node:20-alpine
   ```

1. Commit and push the file to your default branch.

The specified image is used when flows run in CI/CD for your project.
