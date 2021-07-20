---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: 'This article describes how to install Git on macOS, Ubuntu Linux and Windows.'
type: howto
---

# Installing Git **(FREE)**

To begin contributing to GitLab projects,
you must install the Git client on your computer.

This article shows you how to install Git on macOS, Ubuntu Linux and Windows.

Information on [installing Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
is also available at the official Git website.

## Install Git on macOS using the Homebrew package manager

Although you can use the version of Git shipped with macOS or install the latest
version of Git on macOS by downloading it from the project website, we recommend
installing Git with Homebrew to get access to an extensive selection of
dependency-managed libraries and applications.

If you don't need access to any additional development libraries or don't have
approximately 15 GB of available disk space for Xcode and Homebrew, use one of
the previously mentioned methods.

### Installing Xcode

To build dependencies, Homebrew needs the XCode Command Line Tools. Install
it by running in your terminal:

```shell
xcode-select --install
```

Click **Install** to download and install it. Alternatively, you can install
the entire [XCode](https://developer.apple.com/xcode/) package through the
macOS App Store.

### Installing Homebrew

With Xcode installed, browse to the [Homebrew website](https://brew.sh/index.html)
for the official Homebrew installation instructions.

### Installing Git via Homebrew

With Homebrew installed, you are now ready to install Git.
Open a terminal and enter the following command:

```shell
brew install git
```

Congratulations! You should now have Git installed via Homebrew.

To verify that Git works on your system, run:

```shell
git --version
```

Next, read our article on [adding an SSH key to GitLab](../../../ssh/index.md).

## Install Git on Ubuntu Linux

On Ubuntu and other Linux operating systems
it is recommended to use the built-in package manager to install Git.

Open a terminal and enter the following commands
to install the latest Git from the official Git maintained package archives:

```shell
sudo apt-add-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git
```

Congratulations! You should now have Git installed via the Ubuntu package manager.

To verify that Git works on your system, run:

```shell
git --version
```

Next, read our article on [adding an SSH key to GitLab](../../../ssh/index.md).

## Installing Git on Windows from the Git website

Open the [Git website](https://git-scm.com/) and download and install Git for Windows.

Next, read our article on [adding an SSH key to GitLab](../../../ssh/index.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
