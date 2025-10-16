---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Install the GDK development environment
---

If you want to contribute to the GitLab codebase and want a development environment in which to test
your changes, you can use [the GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit),
a local version of GitLab that's yours to play with.

The GDK is a local development environment that includes an installation of GitLab Self-Managed,
sample projects, and administrator access with which you can test functionality.

![Home page of GitLab running in local development environment on port 3000](img/gdk_home_v15_11.png)

If you prefer to use GDK in a local container, use the steps in [Configure GDK-in-a-box](configure-dev-env-gdk-in-a-box.md)

[View an interactive demo of this step](https://gitlab.navattic.com/xtk20s8x).

## Install and configure GitLab Development Kit (GDK)

If you already have a working GDK,
[update it to use the community fork](#update-an-existing-gdk-installation).

Set aside about two hours to install the GDK. If all goes smoothly, it
should take about an hour to install.

Sometimes the installation needs some tweaks to make it work, so you should
also set aside some time for troubleshooting.
It might seem like a lot of work, but after you have the GDK running,
you'll be able to make any changes.

![Home page of GitLab running in local development environment on port 3000](img/gdk_home_v15_11.png)

To install the GDK:

1. Ensure you're on
   [one of the supported platforms](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/main/#supported-platforms).
1. Confirm that [Git](../../../topics/git/how_to_install_git/_index.md) is installed,
   and that you have a source code editor.
1. Choose the directory where you want to install the GDK.
   The installation script installs the application to a new subdirectory called `gdk`.

   Keep the directory name short. Some users encounter issues with long directory names.

1. From the command line, go to that directory.
   In this example, create and change to the `dev` directory:

   ```shell
   mkdir ~/dev && cd ~/dev
   ```

1. Run the one-line installation command:

   ```shell
   curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/install" | bash
   ```

   This script clones the GitLab Development Kit (GDK) repository into a new subdirectory, and sets up necessary dependencies using the `mise` version manager (including Ruby, Node.js, PostgreSQL, Redis, and more).

   {{< alert type="note" >}}

   If you're using another tool version manager for those dependencies, refer to the [tool version manager](#use-a-different-tool-version-manager) to avoid conflicts.

   {{< /alert >}}

1. For the message `Where would you like to install the GDK? [./gdk]`,
   press <kbd>Enter</kbd> to accept the default location.
1. For the message `Which GitLab repo URL would you like to clone?`, enter the GitLab community fork URL:

   ```shell
   https://gitlab.com/gitlab-community/gitlab.git
   ```

1. For the message `GitLab would like to collect basic error and usage data`,
   choose your option based on the prompt.

   While the installation is running, copy any messages that are displayed.
   If you have any problems with the installation, you can use this output as
   part of [troubleshooting](#troubleshoot-gdk).

1. After the installation is complete, you might need to activate `mise`:

   For `bash`:

   ```shell
   eval "$(mise activate bash)"
   ```

   For `zsh`:

   ```shell
   eval "$(mise activate zsh)"
   ```

1. Go to the directory where the GDK was installed:

   ```shell
   cd gdk
   ```

1. Run `gdk truncate-legacy-tables` to ensure that the data in the main and CI databases are truncated,
   then `gdk doctor` to confirm the GDK installation:

   ```shell
   gdk truncate-legacy-tables && gdk doctor
   ```

   - If `gdk doctor` returns errors, consult the [Troubleshoot GDK](#troubleshoot-gdk) section.
   - If `gdk doctor` returns `Your GDK is healthy`, proceed to the next step.

1. Start the GDK:

   ```shell
   gdk start
   ```

1. Wait for `GitLab available at http://127.0.0.1:3000`,
   and connect to the GDK using the URL provided.

1. Sign in with the username `root` and the password `5iveL!fe`. You will be prompted
   to reset your password the first time you sign in.

1. Continue to [Change the code with the GDK](contribute-gdk.md).

## Update an existing GDK installation

If you have an existing GDK installation, you should update it to use the community fork.

1. Delete the existing `gdk/gitlab` directory.
1. Clone the community fork into that location:

   ```shell
   cd gdk
   git clone https://gitlab.com/gitlab-community/gitlab.git
   ```

To confirm it was successful:

1. Ensure the `gdk/gitlab` directory exists.
1. Go to the top `gdk` directory and run `gdk stop` and `gdk start`.

If you get errors, run `gdk doctor` to troubleshoot.
For more advanced troubleshooting, continue to the [Troubleshoot GDK](#troubleshoot-gdk) section.

## Use a different tool version manager

If you are using a different tool version manager in your system, you may encounter issues as only `mise` as a tool version manager is officially supported.

When using `asdf` as your tool version manager, you can use the following command to migrate to `mise`:

1. Run the migration command:

   ```shell
   gdk rake mise:migrate
   ```

Refer to the [migration instructions](https://gitlab-org.gitlab.io/gitlab-development-kit/howto/mise/#how-to-migrate) for more information.

In case you want to continue using a different tool version manager, you need to configure the GDK for it.

1. Set GDK not to use the default tool version manager:

   ```shell
   gdk config set tool_version_manager.enabled false
   ```

## Troubleshoot GDK

{{< alert type="note" >}}

For more advanced troubleshooting, see
the [troubleshooting documentation](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/main/doc/troubleshooting)
and the [#contribute channel on Discord](https://discord.com/channels/778180511088640070/997442331202564176).

{{< /alert >}}

If you encounter issues, go to the `gdk/gitlab`
directory and run `gdk doctor`.

If `gdk doctor` returns Node or Ruby-related errors, run:

```shell
yarn install && bundle install
bundle exec rails db:migrate RAILS_ENV=development
```

## Change the code

After the GDK is ready, continue to [Contribute code with the GDK](contribute-gdk.md).
