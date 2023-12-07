---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 'This article describes how to install Git on macOS, Ubuntu Linux and Windows.'
---

# Installing Git **(FREE ALL)**

To begin contributing to GitLab projects, you must install the appropriate Git client
on your computer. Information about [installing Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
is also available at the official Git website.

## Supported operating systems

Git is available for the following operating systems:

- [macOS](#macos)
- [Ubuntu Linux](#ubuntu-linux)
- [Microsoft Windows](#windows)

### macOS

A version of Git is supplied by macOS. You can use this version, or install the latest
version of Git on macOS by downloading it from the project website. We recommend
installing Git with [Homebrew](https://brew.sh/index.html). With Homebrew, you can
access an extensive selection of libraries and applications, with their dependencies
managed for you.

Prerequisites:

- 15 GB of available disk space for Homebrew and Xcode.
- Extra disk space for any additional development libraries.

To install Git on macOS:

1. Open a terminal and install Xcode Command Line Tools:

   ```shell
   xcode-select --install
   ```

   Alternatively, you can install the entire [Xcode](https://developer.apple.com/xcode/)
   package through the macOS App Store.

1. Select **Install** to download and install Xcode Command Line Tools.
1. Install Homebrew according to the [official Homebrew installation instructions](https://brew.sh/index.html).
1. Install Git by running `brew install git` from your terminal.
1. In a terminal, verify that Git works on your computer:

   ```shell
   git --version
   ```

#### macOS update

Periodically you may need to update the version of Git installed by
[Homebrew](/ee/topics/git/how_to_install_git/index.md#macos). To do so,
open a terminal and run these commands:

```shell
brew update
brew upgrade git
```

To verify you are on the updated version, run `git --version` to display
your current version of Git.

### Ubuntu Linux

On Ubuntu and other Linux operating systems, use the built-in package manager
to install Git:

1. Open a terminal and run these commands to install the latest Git
from the officially
   maintained package archives:

   ```shell
   sudo apt-add-repository ppa:git-core/ppa
   sudo apt-get update
   sudo apt-get install git
   ```

1. To verify that Git works on your computer, run:

   ```shell
   git --version
   ```

#### Ubuntu Linux Update

Periodically it may be necessary to update Git installed. To do so, run the same [commands](/ee/topics/git/how_to_install_git/index.md#ubuntu-linux).

### Windows

Go to the [Git website](https://git-scm.com/), and then download and install Git for Windows.

## After you install Git

After you successfully install Git on your computer, read about [adding an SSH key to GitLab](../../../user/ssh.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
