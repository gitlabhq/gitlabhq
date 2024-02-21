---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Configure the GDK development environment

If you want to contribute to the GitLab codebase and want a development environment in which to test
your changes, you can use [the GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit),
a local version of GitLab that's yours to play with.

It's just like an installation of self-managed GitLab. It includes sample projects you can use
to test functionality, and it gives you access to administrator functionality.

![GDK](../img/gdk_home.png)

[GDK-in-a-box](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/gdk_in_a_box.md)
is a virtual machine (VM) pre-configured with GDK.
It requires 30 GB of disk space.

<!--
The steps here are a version of the steps in the GDK repo
https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/gdk_in_a_box.md
-->

## Download GDK-in-a-box

1. Download and install virtualization software to run the virtual machine:
   - Mac computers with [Apple silicon](https://support.apple.com/en-us/116943):
   [UTM](https://docs.getutm.app/installation/macos/). Select **Download from GitHub**.
   - Linux / Windows / Mac computers with Intel silicon: [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
1. Download and unzip GDK-in-a-box. The file is up to 10 GB and might take some time to download:
   - Mac computers with Apple silicon: [UTM image](https://go.gitlab.com/cCHpCP)
   - Linux / Windows / Mac: [VirtualBox image](https://go.gitlab.com/5iydBP)
1. Open UTM or VirtualBox, add the virtual machine image, then start the virtual machine:
   - UTM: `gdk.utm`
   - VirtualBox: `gdk.vbox`
1. Continue to **Use VS Code to connect to GDK in the VM**.

## Use VS Code to connect to GDK in the VM

[View a demo video of this step](https://go.gitlab.com/b54mHb).

1. Start the VM. You can minimize UTM or VirtualBox.

1. In VS Code, select **Terminal > New terminal** and run a `curl` command that executes a script to
   add an SSH key to your local `~/.ssh/config`:

   ```shell
   curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/gdk-in-a-box/setup-ssh-key" | bash
   ```

   To learn more about the script, you can examine the
   [`setup-ssh-key` code](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/support/gdk-in-a-box/setup-ssh-key).

1. In VS Code, install the **Remote - SSH** extension:
   - [VS Code](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)
   - [VSCodium](https://open-vsx.org/extension/jeanp413/open-remote-ssh)
1. Connect VS Code to the VM:
   - Select **Remote-SSH: Connect to host** from the command palette.
   - Enter the SSH host: `debian@gdk.local`
1. A new VS Code window opens.
   You can close or minimize the old window to avoid confusion.

   Complete the remaining steps in this section in the new VS Code window.

1. In the VS Code terminal, run a `curl` command to run a script to configure Git in the GDK:

   ```shell
   curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/gdk-in-a-box/setup-git" | bash
   ```

   - Enter your name and email address when prompted.
   - Add the displayed [SSH key to your profile](https://gitlab.com/-/profile/keys).

   To learn more about the script, you can examine the
   [`setup-git` code](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/support/gdk-in-a-box/setup-git).

1. In VS Code, select **File > Open folder**, and go to: `/home/debian/gitlab-development-kit/gitlab/`.
1. Open GitLab in your browser: [http://gdk.local:3000](http://gdk.local:3000).
1. Sign in with the username `root` and the password `5iveL!fe`.
1. Continue to [Change the code with the GDK](contribute-gdk.md).

### Shut down GDK in the VM

You can select the power icon <i class="fa fa-power-off" aria-hidden="true"></i> to shut down
the virtual machine, or enter the `shutdown` command in the terminal. Use the password `debian`:

```shell
sudo shutdown now
```

### Update GDK-in-a-box

You can update GDK-in-a-box while connected to `debian@gdk.local` in VS Code.

In the VS Code terminal, enter `gdk update`.

## Install GDK and its dependencies

If you prefer to install GDK without a virtual machine, you can use the one-line GDK-installation.

<details><summary>Traditional, one-line GDK installation</summary>

If you already have a working GDK,
[update it to use the community fork](#update-an-existing-gdk-installation).

[View an interactive demo of this step](https://gitlab.navattic.com/xtk20s8x).

### Install and configure GitLab Development Kit (GDK)

If you already have a working GDK,
[update it to use the community fork](#update-an-existing-gdk-installation).

Set aside about two hours to install the GDK. If all goes smoothly, it
should take about an hour to install.

Sometimes the installation needs some tweaks to make it work, so you should
also set aside some time for troubleshooting.
It might seem like a lot of work, but after you have the GDK running,
you'll be able to make any changes.

[View an interactive demo](https://gitlab.navattic.com/ak10d67) of this step.

![GitLab in GDK](../img/gdk_home.png)

To install the GDK:

1. Ensure you're on
   [one of the supported platforms](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/main/#supported-platforms).
1. Confirm that [Git](../../../topics/git/how_to_install_git/index.md) is installed,
   and that you have a source code editor.
1. Choose the directory where you want to install the GDK.
   The installation script installs the application to a new subdirectory called `gitlab-development-kit`.

   Keep the directory name short. Some users encounter issues with long directory names.

1. From the command line, go to that directory.
   In this example, create and change to the `dev` directory:

   ```shell
   mkdir ~/dev && cd "$_"
   ```

1. Run the one-line installation command:

   ```shell
   curl "https://gitlab.com/gitlab-org/gitlab-development-kit/-/raw/main/support/install" | bash
   ```

1. For the message `Where would you like to install the GDK? [./gitlab-development-kit]`,
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

1. After the installation is complete,
   copy the `source` command from the message corresponding to your shell
   from the message `INFO: To make sure GDK commands are available in this shell`:

   ```shell
   source ~/.asdf/asdf.sh
   ```

1. Go to the directory where the GDK was installed:

   ```shell
   cd gitlab-development-kit
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

### Update an existing GDK installation

If you have an existing GDK installation, you should update it to use the community fork.

1. Delete the existing `gitlab-development-kit/gitlab` directory.
1. Clone the community fork into that location:

   ```shell
   cd gitlab-development-kit
   git clone https://gitlab.com/gitlab-community/gitlab.git
   ```

To confirm it was successful:

1. Ensure the `gitlab-development-kit/gitlab` directory exists.
1. Go to the top `gitlab-development-kit` directory and run `gdk stop` and `gdk start`.

If you get errors, run `gdk doctor` to troubleshoot.
For more advanced troubleshooting, continue to the [Troubleshoot GDK](#troubleshoot-gdk) section.

### Troubleshoot GDK

If you encounter issues, go to the `gitlab-development-kit/gitlab`
directory and run `gdk doctor`.

If `gdk doctor` returns Node or Ruby-related errors, run:

```shell
yarn install && bundle install
bundle exec rails db:migrate RAILS_ENV=development
```

For more advanced troubleshooting, see
the [troubleshooting documentation](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/main/doc/troubleshooting)
and the [#contribute channel on Discord](https://discord.com/channels/778180511088640070/997442331202564176).

### Change the code

After the GDK is ready, continue to [Contribute code with the GDK](contribute-gdk.md).

</details>
