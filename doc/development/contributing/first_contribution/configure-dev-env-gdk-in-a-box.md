---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Configure GDK-in-a-box

If you want to contribute to the GitLab codebase and want a development environment in which to test
your changes, you can use
[GDK-in-a-box](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/gdk_in_a_box.md),
a virtual machine (VM) pre-configured with [the GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit).

The GDK is a local development environment that includes an installation of self-managed GitLab,
sample projects, and administrator access with which you can test functionality.

It requires 30 GB of disk space.

![GDK](../img/gdk_home.png)

If you prefer to use GDK locally without a VM, use the steps in [Install the GDK development environment](configure-dev-env-gdk.md)

Follow the steps defined in the [GDK-in-a-box docs](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/gdk_in_a_box.md)
to download, configure and update GDK-in-a-box.

## Change the code

After the GDK is ready, continue to [Contribute code with the GDK](contribute-gdk.md).
