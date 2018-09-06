# Protected Environments

> [Introduced][6303] in [GitLab Premium][ee] 11.3.

## Overview

[Environments](../environments.md) can be used for different scopes, some of
them are just for testing while others are for production. As deploy jobs could
be raised by different users with different roles, it is very important that
specific environments are "protected" to avoid unauthorized people to affect them.

By default, a protected environment does one thing: it ensures that only people
with the right privileges can deploy to it, thus keeping it safe.

NOTE: **Note**:
A GitLab admin is always allowed to use environments, even if they are protected.

To protect, update, or unprotect an environment, you need to have at least
[Maintainer permissions](../../user/permissions.md).

## Configuring protected environments

To protect an environment:

1. Navigate to your project's **Settings ➔ CI/CD**.
1. Scroll to find the **Protected Environments** section.
1. From the **Environment** dropdown menu, select the environment you want to protect and
   click **Protect**.
1. In the "Allowed to Deploy" dropdown menu, you can select the role and/or the
   users and/or the groups you want to have deploy access. There are some
   considerations to have in mind:
    - There are two roles to choose from:
      - **Maintainers**: will allow access to all maintainers in the project.
      - **Developers**: will allow access to all maintainers and all developers in the project.
    - You can only select groups that are associated with the project.
    - Only users that have at least Developer permission level will appear on
      the "Allowed to Deploy" dropdown menu.

1. Once done, the protected environment will appear in the "Protected Environments"
   list.

Maintainers can update existing protected environments at any time
by changing the access on "Allowed to Deploy" dropdown menu. Similarly,
to unprotect a protected environment, Maintainers need to click the
**Unprotect** button of the respective environment.

[ee]: https://about.gitlab.com/pricing/
[6303]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6303
