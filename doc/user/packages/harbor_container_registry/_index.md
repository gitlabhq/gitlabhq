---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Harbor registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - **Harbor Registry** [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/439494) from the **Operate** menu section to **Deploy** in GitLab 17.0.

You can integrate the [Harbor container registry](../../project/integrations/harbor.md) into GitLab and use Harbor as the container registry for your GitLab project to store images.

## View the Harbor registry

You can view the Harbor registry for a project or group.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Deploy > Harbor Registry**.

You can search, sort, and filter images on this page. You can share a filtered view by copying the URL from your browser.

At the project level, in the upper-right corner, you can see **CLI Commands** where you can copy
corresponding commands to sign in, build images, and push images. **CLI Commands** is not shown at
the group level.

NOTE:
Default settings for the Harbor integration at the project level are inherited from the group level.

## Use images from the Harbor registry

To download and run a Harbor image hosted in the GitLab Harbor registry:

1. Copy the link to your container image:
   1. On the left sidebar, select **Search or go to** and find your project or group.
   1. Select **Deploy > Harbor Registry** and find the image you want.
   1. Select the **Copy** icon next to the image name.

1. Use the command to run the container image you want.

## View the tags of a specific artifact

To view the list of tags associated with a specific artifact:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Go to **Deploy > Harbor Registry**.
1. Select the image name to view its artifacts.
1. Select the artifact you want.

This brings up the list of tags. You can view the tag count and the time published.

You can also copy the tag URL and use it to pull the corresponding artifact.

## Build and push images by using commands

To build and push to the Harbor registry:

1. Authenticate with the Harbor registry.
1. Run the command to build or push.

To view these commands:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Deploy > Harbor Registry**.
1. Select **CLI Commands**.

## Disable the Harbor registry for a project

To remove the Harbor registry for a project:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Integrations**.
1. Select **Harbor** under **Active integrations**.
1. Under **Enable integration**, clear the **Active** checkbox.
1. Select **Save changes**.

The **Deploy > Harbor Registry** entry is removed from the sidebar.
