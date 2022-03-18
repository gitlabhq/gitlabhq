---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Harbor container registry integration **(FREE)**

Use Harbor as the container registry for your GitLab project.

[Harbor](https://goharbor.io/) is an open source registry that can help you manage artifacts across cloud native compute platforms, like Kubernetes and Docker.

This integration can help you if you need GitLab CI/CD and a container image repository.

## Prerequisites

In the Harbor instance, ensure that:

- The project to be integrated has been created.
- The signed-in user has permission to pull, push, and edit images in the Harbor project.

## Configure GitLab

GitLab supports integrating Harbor projects at the group or project level. Complete these steps in GitLab:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Integrations**.
1. Select **Harbor**.
1. Turn on the **Active** toggle under **Enable Integration**.
1. Provide the Harbor configuration information:
   - **Harbor URL**: The base URL of Harbor instance which is being linked to this GitLab project. For example, `https://harbor.example.net`.
   - **Harbor project name**: The project name in the Harbor instance. For example, `testproject`.  
   - **Username**: Your username in the Harbor instance, which should meet the requirements in [prerequisites](#prerequisites).
   - **Password**: Password of your username.

1. Select **Save changes**.

After the Harbor integration is activated:

- The global variables `$HARBOR_USER`, `$HARBOR_PASSWORD`, `$HARBOR_URL`, and `$HARBOR_PROJECT` are created for CI/CD use.
- The project-level integration settings override the group-level integration settings.

## Secure your requests to the Harbor APIs

For each API request through the Harbor integration, the credentials for your connection to the Harbor API use
the `username:password` combination. The following are suggestions for safe use: 

- Use TLS on the Harbor APIs you connect to.
- Follow the principle of least privilege (for access on Harbor) with your credentials.
- Have a rotation policy on your credentials.
