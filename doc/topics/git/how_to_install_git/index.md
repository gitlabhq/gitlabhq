---
author: Sean Packham
author_gitlab: SeanPackham
level: beginner
article_type: user guide
date: 2017-05-15
---

# Installing Git

To begin contributing to GitLab projects
you will need to install the Git client on your computer.
This article will show you how to install Git on macOS, Ubuntu Linux and Windows.

## Install Git on macOS using the Homebrew package manager

Although it is easy to use the version of Git shipped with macOS
or install the latest version of Git on macOS by downloading it from the project website,
we recommend installing it via Homebrew to get access to
an extensive selection of dependency managed libraries and applications.

If you are sure you don't need access to any additional development libraries
or don't have approximately 15gb of available disk space for Xcode and Homebrew
use one of the the aforementioned methods.

### Installing Xcode

Xcode is needed by Homebrew to build dependencies.
You can install [XCode](https://developer.apple.com/xcode/)
through the macOS App Store.

### Installing Homebrew

Once Xcode is installed browse to the [Homebrew website](http://brew.sh/index.html)
for the official Homebrew installation instructions.

### Installing Git via Homebrew

With Homebrew installed you are now ready to install Git.
Open a Terminal and enter in the following command:

```bash
brew install git
```

Congratulations you should now have Git installed via Homebrew.
Next read our article on [adding an SSH key to GitLab](../../../ssh/README.md).

## Install Git on Ubuntu Linux

On Ubuntu and other Linux operating systems
it is recommended to use the built in package manager to install Git.

Open a Terminal and enter in the following commands
to install the latest Git from the official Git maintained package archives:

```bash
sudo apt-add-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git
```

Congratulations you should now have Git installed via the Ubuntu package manager.
Next read our article on [adding an SSH key to GitLab](../../../ssh/README.md).

## Installing Git on Windows from the Git website

Browse to the [Git website](https://git-scm.com/) and download and install Git for Windows.
Next read our article on [adding an SSH key to GitLab](../../../ssh/README.md).
