---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "How to install Git on your local machine."
---

# Install and configure Git

To begin contributing to GitLab projects, you must download and install the Git client on your computer.

This page provides information on installing Git on macOS and Ubuntu Linux.

For information on downloading and installing Git on other operating systems, see the
[official Git website](https://git-scm.com/downloads).

## Install and update Git

::Tabs

:::TabTitle macOS

Though a version of Git is supplied by macOS, you should install the latest version of Git. A common way to
install Git is with [Homebrew](https://brew.sh/index.html).

To install the latest version of Git on macOS with Homebrew:

1. If you've never installed Homebrew before, follow the
   [Homebrew installation instructions](https://brew.sh/index.html).
1. In a terminal, install Git by running `brew install git`.
1. Verify that Git works on your computer:

   ```shell
   git --version
   ```

Keep Git up to date by periodically running the following command:

```shell
brew update && brew upgrade git
```

:::TabTitle Ubuntu Linux

Though a version of Git is supplied by Ubuntu, you should install the latest version of Git. The latest version is
available using a Personal Package Archive (PPA).

To install the latest version of Git on Ubuntu Linux with a PPA:

1. In a terminal, configure the required PPA, update the list of Ubuntu packages, and install `git`:

   ```shell
   sudo apt-add-repository ppa:git-core/ppa
   sudo apt-get update
   sudo apt-get install git
   ```

1. Verify that Git works on your computer:

   ```shell
   git --version
   ```

Keep Git up to date by periodically running the following command:

```shell
sudo apt-get update && sudo apt-get install git
```

::EndTabs

## Configure Git

To start using Git from your computer, you must enter your credentials
to identify yourself as the author of your work. The full name and
email address should match the ones you use in GitLab.

1. In your terminal, add your full name. For example:

   ```shell
   git config --global user.name "Sidney Jones"
   ```

1. Add your email address. For example:

   ```shell
   git config --global user.email "your_email_address@example.com"
   ```

1. To check the configuration, run:

   ```shell
   git config --global --list
   ```

   The `--global` option tells Git to always use this information for anything you do on your system.
   If you omit `--global` or use `--local`, the configuration applies only to the current
   repository.

After you set your name and email address, you should add an SSH key.
See [Use SSH keys to communicate with GitLab](../../../user/ssh.md).

## Related topics

- [Git configuration documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
