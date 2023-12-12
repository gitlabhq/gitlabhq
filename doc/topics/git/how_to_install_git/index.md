---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Installing Git **(FREE ALL)**

To begin contributing to GitLab projects, you must download and install the Git client on your computer.

This page provides information on installing Git on the following operating systems:

- macOS
- Ubuntu Linux
- Microsoft Windows

For information on downloading and installing Git on other operating systems, see the
[official Git website](https://git-scm.com/downloads).

## Install and update Git on macOS

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

## Install and update Git on Ubuntu Linux

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

## Install Git on Microsoft Windows

For information on downloading and installing Git on Microsoft Windows, see the
[official Git documentation](https://git-scm.com/download/win).

## After you install Git

After you successfully install Git on your computer, read about [adding an SSH key to GitLab](../../../user/ssh.md).
