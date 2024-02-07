---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Tutorial: Make a GitLab contribution

Anyone can contribute to the development of GitLab.

Maybe you want to add functionality that you feel is missing.
Or maybe you noticed some UI text that you want to improve.

This tutorial will walk you through the process of updating UI text
and related files using Gitpod or the GitLab Development Kit on the GitLab community fork.
You can follow this example to familiarize yourself with the process.

NOTE:
Join the [GitLab Discord server](https://discord.gg/gitlab), where GitLab team
members and the wider community are ready and waiting to answer your questions
and ensure [everyone can contribute](https://handbook.gitlab.com/handbook/company/mission/).

## Before you begin

- If you don't already have a GitLab account [create a new one](https://gitlab.com/users/sign_up).
  Confirm you can successfully [sign in](https://gitlab.com/users/sign_in).
- [Request access to the community forks](https://gitlab.com/groups/gitlab-community/community-members/-/group_members/request_access),
  a set of forks mirrored from GitLab repositories in order to improve the contributor experience.
  - For more information, read the [community forks blog post](https://about.gitlab.com/blog/2023/04/04/gitlab-community-forks/).
  - The access request will be manually verified and should take no more than a few hours.
  - If you use a local development environment, you can start making changes locally before your access is granted.
    You must have access to the community fork to push your changes to it.

## Choose how you want to contribute

The three methods outlined in this tutorial cover:

- Quick Change: Use the Web IDE to submit a quick code change from your browser.
- GitLab Development Kit (GDK)
  - Local development environment.
  - It's just like an installation of self-managed GitLab. It includes sample projects you
    can use to test functionality, and it gives you access to administrator functionality.
- Gitpod - Most contributors should use this option.
  - Remote development environment that runs the GDK remotely, regardless of your local hardware,
    operating system, or software.
  - Make and preview remote changes in your local browser.

The steps for each method vary in time and effort.
You should choose the one that fits your needs.

::Tabs

:::TabTitle Quick Change - Remote IDE. No preview.

Use the [Web IDE](../../../user/project/web_ide/index.md) to adjust code or language from your browser.

1. [Change the code](contribute-web-ide.md)
1. [Create a merge request](mr-review.md)

:::TabTitle Gitpod - Remote IDE, environment, and preview.

Use Gitpod to make changes from your browser to a remote GitLab environment.

Gitpod takes a few minutes to set up and is fully ready in thirty minutes.

1. [Configure the remote development environment](configure-dev-env-gitpod.md)
1. [Change the code](contribute-gitpod.md)
1. [Create a merge request](mr-review.md)

:::TabTitle GDK - Local environment and preview.

A local development environment and full installation of self-managed GitLab, complete with sample projects.

GDK takes an hour to set up, depending on your local hardware.

1. [Configure the development environment](configure-dev-env-gdk.md)
1. [Change the code](contribute-gdk.md)
1. [Create a merge request](mr-review.md)

::EndTabs
