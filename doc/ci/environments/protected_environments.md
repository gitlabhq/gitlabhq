# Protected Environments **[PREMIUM]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6303) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.3.

## Overview

[Environments](../environments.md) can be used for different reasons:

- Some of them are just for testing.
- Others are for production.

Because deploy jobs can be raised by different users with different roles, it is important that
specific environments are "protected" to avoid unauthorized people affecting them.

By default, a protected environment does one thing: it ensures that only people
with the right privileges can deploy to it, thus keeping it safe.

NOTE: **Note**:
A GitLab admin is always allowed to use environments, even if they are protected.

To protect, update, or unprotect an environment, you need to have at least
[Maintainer permissions](../../user/permissions.md).

## Protecting environments

To protect an environment:

1. Navigate to your project's **Settings > CI/CD**.
1. Expand the **Protected Environments** section.
1. From the **Environment** dropdown menu, select the environment you want to protect.
1. In the **Allowed to Deploy** dropdown menu, select the role, users, or  groups you want to have deploy access.
   There are some considerations to have in mind:
    - There are two roles to choose from:
      - **Maintainers**: will allow access to all maintainers in the project.
      - **Developers**: will allow access to all maintainers and all developers in the project.
    - You can only select groups that are associated with the project.
    - Only users that have at least Developer permission level will appear on
      the **Allowed to Deploy** dropdown menu.
1. Click the **Protect** button.

The protected environment will now appear in the list of protected environments.

## Modifying and unprotecting environments

Maintainers can:

- Update existing protected environments at any time by changing the access on **Allowed to deploy** dropdown menu.
- Unprotect a protected environment by clicking the **Unprotect** button of the environment to unprotect.
