---
comments: false
description: 'Learn how to use and administer GitLab, the most scalable Git-based fully integrated platform for software development.'
---

# GitLab Documentation

Welcome to [GitLab](https://about.gitlab.com/), a Git-based fully featured
platform for software development!

GitLab offers the most scalable Git-based fully integrated platform for
software development, with flexible products and subscriptions.
To understand what features you have access to, check the [GitLab subscriptions](#gitlab-subscriptions) below.

**Shortcuts to GitLab's most visited docs:**

| General documentation                                       | GitLab CI/CD docs                                               |
|:------------------------------------------------------------|:----------------------------------------------------------------|
| [User documentation](user/index.md)                         | [GitLab CI/CD quick start guide](ci/quick_start/README.md)      |
| [Administrator documentation](administration/index.md)      | [GitLab CI/CD examples](ci/examples/README.md)                  |
| [Contributor documentation](#contributor-documentation)     | [Configuring `.gitlab-ci.yml`](ci/yaml/README.md)               |
| [Getting started with GitLab](#getting-started-with-gitlab) | [Using Docker images](ci/docker/using_docker_images.md)         |
| [API](api/README.md)                                        | [Auto DevOps](topics/autodevops/index.md)                       |
| [SSH authentication](ssh/README.md)                         | [Kubernetes integration](user/project/clusters/index.md)        |
| [GitLab Pages](user/project/pages/index.md)                 | [GitLab Container Registry](user/project/container_registry.md) |

## Complete DevOps with GitLab

GitLab is the first single application for software development, security,
and operations that enables Concurrent DevOps, making the software lifecycle
three times faster and radically improving the speed of business. GitLab
provides solutions for all the stages of the DevOps lifecycle:

- [Plan](plan.md)
- [Create](create.md)
- [Verify](verify.md)
- [Package](package.md)
- [Release](release.md)
- [Configure](configure.md)
- [Monitor](monitor.md)

![DevOps Lifecycle](img/devops_lifecycle.png)

## Getting started with GitLab

- [GitLab Basics](gitlab-basics/README.md): Start working on your command line and on GitLab.
- [GitLab Workflow](workflow/README.md): Enhance your workflow with the best of GitLab Workflow.
  - See also [GitLab Workflow - an overview](https://about.gitlab.com/2016/10/25/gitlab-workflow-an-overview/).
- [GitLab Markdown](user/markdown.md): GitLab's advanced formatting system (GitLab Flavored Markdown).

### User account

- [User account](user/profile/index.md): Manage your account
  - [Authentication](topics/authentication/index.md): Account security with two-factor authentication, set up your ssh keys and deploy keys for secure access to your projects.
  - [Profile settings](user/profile/index.md#profile-settings): Manage your profile settings, two factor authentication and more.
- [User permissions](user/permissions.md): Learn what each role in a project (external/guest/reporter/developer/maintainer/owner) can do.

### Git and GitLab

- [Git](topics/git/index.md): Getting started with Git, branching strategies, Git LFS, advanced use.
- [Git cheatsheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf): Download a PDF describing the most used Git operations.
- [GitLab Flow](workflow/gitlab_flow.md): explore the best of Git with the GitLab Flow strategy.

## Administrator documentation

[Administration documentation](administration/index.md) applies to admin users of GitLab
self-hosted instances.

Learn how to install, configure, update, upgrade, integrate, and maintain your own instance.
Regular users don't have access to GitLab administration tools and settings.

## Contributor documentation

GitLab Community Edition is [open source](https://gitlab.com/gitlab-org/gitlab-ce/)
and GitLab Enterprise Edition is [open-core](https://gitlab.com/gitlab-org/gitlab-ee/).
Learn how to contribute to GitLab:

- [Development](development/README.md): All styleguides and explanations how to contribute.
- [Legal](legal/README.md): Contributor license agreements.
- [Writing documentation](development/documentation/index.md): Contributing to GitLab Docs.

## GitLab subscriptions

You have two options to use GitLab:

- GitLab self-hosted: Install, administer, and maintain your own GitLab instance.
- GitLab.com: GitLab's SaaS offering. You don't need to install anything to use GitLab.com,
you only need to [sign up](https://gitlab.com/users/sign_in) and start using GitLab
straight away.

### GitLab self-hosted

With GitLab self-hosted, you deploy your own GitLab instance on-premises or on a private cloud of your choice. GitLab self-hosted is available for [free and with paid subscriptions](https://about.gitlab.com/pricing/): Core, Starter, Premium, and Ultimate.

Every feature available in Core is also available in Starter, Premium, and Ultimate.
Starter features are also available in Premium and Ultimate, and Premium features are also
available in Ultimate.

### GitLab.com

GitLab.com is hosted, managed, and administered by GitLab, Inc., with
[free and paid subscriptions](https://about.gitlab.com/gitlab-com/) for individuals
and teams: Free, Bronze, Silver, and Gold.

GitLab.com subscriptions grants access
to the same features available in GitLab self-hosted, **except
[administration](administration/index.md) tools and settings**:

- GitLab.com Free includes the same features available in Core
- GitLab.com Bronze includes the same features available in GitLab Starter
- GitLab.com Silver includes the same features available in GitLab Premium
- GitLab.com Gold includes the same features available in GitLab Ultimate

For supporting the open source community and encouraging the development of
open source projects, GitLab grants access to **Gold** features
for all GitLab.com **public** projects, regardless of the subscription.

To know more about GitLab subscriptions and licensing, please refer to the
[GitLab Product Marketing Handbook](https://about.gitlab.com/handbook/marketing/product-marketing/#tiers).
