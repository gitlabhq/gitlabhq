---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: 'Tutorial: Make a GitLab contribution'
---

Everyone can contribute to the development of GitLab.
You can contribute new features, changes to code or processes, typo fixes,
or updates to language in the interface.

This tutorial walks you through the contribution process with an example of updating UI text and related files.
You can follow this tutorial to familiarize yourself with the contribution process.

## Before you begin

1. If you don't already have a GitLab account [create a new one](https://gitlab.com/users/sign_up).
   Confirm you can successfully [sign in](https://gitlab.com/users/sign_in).
1. [Request access to the community forks](https://gitlab.com/groups/gitlab-community/community-members/-/group_members/request_access),
   a set of forks mirrored from GitLab repositories in order to improve the contributor experience.
   - When you request access to the community forks you will receive an onboarding issue in the
[community onboarding project](https://gitlab.com/gitlab-community/community-members/onboarding/-/issues).
   - For more information, read the [community forks blog post](https://about.gitlab.com/blog/2023/04/04/gitlab-community-forks/).
   - The access request will be manually verified and should take no more than a few hours.
   - If you use a local development environment, you can start making changes locally while you wait
     for the team to confirm your access.
     You must have access to the community fork to push your changes to it.
1. We recommend you join the [GitLab Discord server](https://discord.com/invite/gitlab), where GitLab team
   members and the wider community are ready and waiting to answer your questions and offer support
   for making contributions.
1. Once your community forks access request is approved you can start using [GitLab Duo](../../../user/gitlab_duo/_index.md),
   our AI-powered features including Code Suggestions, Chat, Root Cause Analysis, and more.

## Choose how you want to contribute

To get started, select the development option that works best for you:

- [**Web IDE**](contribute-web-ide.md) - Make a quick change from your browser.

  Use the Web IDE to change code or fix a typo and create a merge request from your browser.

  - No configuration or installation required.
  - Available within a few seconds.

- [**Gitpod**](configure-dev-env-gitpod.md) - Most contributors should use this option.
  - In-browser remote development environment that runs regardless of your local hardware,
    operating system, or software.
  - Make and preview remote changes in your local browser.
  - Takes a few minutes to set up and is fully ready in thirty minutes.

- GitLab Development Kit (GDK) and GDK-in-a-box - Fully local development.

  GDK is a local development environment that includes an installation of GitLab Self-Managed,
  sample projects, and administrator access with which you can test functionality.
  These options rely on local hardware and may be resource intensive.

  - [**GDK-in-a-box**](configure-dev-env-gdk-in-a-box.md): Recommended for local development.

    Download and run a pre-configured virtual machine image that contains the GDK, then connect to it with VS Code.

    - Minimal configuration required.
    - After the 10 GB image has downloaded, GDK-in-a-box is ready in a few minutes.

  - [**Standalone GDK**](configure-dev-env-gdk.md): Install the GDK and its dependencies.

    Install the GDK for a fully local development environment.

    - Some configuration required.
    - May take up to two hours to install and configure.
