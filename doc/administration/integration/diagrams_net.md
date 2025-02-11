---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Configure a Diagrams.net integration for GitLab Self-Managed."
title: Diagrams.net
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86206) in GitLab 15.10.
> - Offline environment support [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116281) in GitLab 16.1.

With the [diagrams.net](https://www.drawio.com/) integration, you can create and embed SVG diagrams in wikis.
The diagram editor is available in both the plain text editor and the rich text editor.

On GitLab.com, this integration is enabled for all SaaS users and does not require any additional configuration.

On GitLab Self-Managed, you can choose to integrate with the free [diagrams.net](https://www.drawio.com/)
website, or host your own diagrams.net site in offline environments.

To set up the integration, you must:

1. Choose to integrate with the free diagrams.net website or
   [configure your diagrams.net server](#configure-your-diagramsnet-server).
1. [Enable the integration](#enable-diagramsnet-integration).

After completing the integration, the diagrams.net editor opens with the URL you provided.

## Configure your diagrams.net server

You can set up your own diagrams.net server to generate the diagrams.

It's a required step for users on an offline installation of GitLab Self-Managed.

For example, to run a diagrams.net container in Docker, run the following command:

```shell
docker run -it --rm --name="draw" -p 8080:8080 -p 8443:8443 jgraph/drawio
```

Make note of the hostname of the server running the container, to be used as the diagrams.net URL
when you enable the integration.

For more information, see [Run your own diagrams.net server with Docker](https://www.drawio.com/blog/diagrams-docker-app).

## Enable Diagrams.net integration

1. Sign in to GitLab as an [Administrator](../../user/permissions.md) user.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Diagrams.net**.
1. Select the **Enable Diagrams.net** checkbox.
1. Enter the Diagrams.net URL. To connect to:
   - The free public instance: enter `https://embed.diagrams.net`.
   - A locally hosted diagrams.net instance: enter the URL you [configured earlier](#configure-your-diagramsnet-server).
1. Select **Save changes**.
