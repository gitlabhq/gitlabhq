---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# Configure your environment

## Install

- **Windows** - Install 'Git for Windows' from [Git for Windows](https://gitforwindows.org).
- **Mac**
  - Type '`git`' in the Terminal application.
  - If it's not installed, it prompts you to install it.

- **GNU/Linux** - Enter `which git` in the Terminal application and press <kbd>Enter</kbd> to
  determine if Git is installed on your system.

  - If the output of that command gives you the path to the Git executable, similar to
    `/usr/bin/git`, then Git is already installed on your system.
  - If the output of the command displays "command not found" error, Git isn't installed on your system.

  GitLab recommends installing Git with the default package manager of your distribution.
  The following commands install Git on various GNU/Linux distributions using their
  default package managers. After you run the command corresponding to your distribution
  and complete the installation process, Git should be available on your system:

  - **Arch Linux and its derivatives** - `sudo pacman -S git`
  - **Fedora, RHEL, and CentOS** - For the `yum` package manager run `sudo yum install git-all`,
    and for the `dnf` package manager run `sudo dnf install git`.
  - **Debian/Ubuntu and their derivatives** - `sudo apt-get install git`
  - **Gentoo** - `sudo emerge --ask --verbose dev-vcs/git`
  - **openSUSE** - `sudo zypper install git`
- **FreeBSD** - `sudo pkg install git`
- **OpenBSD** - `doas pkg_add git`

## Configure Git

One-time configuration of the Git client

```shell
git config --global user.name "Your Name"
git config --global user.email you@example.com
```

## Configure SSH Key

```shell
ssh-keygen -t rsa -b 4096 -C "you@computer-name"
```

```shell
# You will be prompted for the following information. Press enter to accept the defaults. Defaults appear in parentheses.
Generating public/private rsa key pair.
Enter file in which to save the key (/Users/you/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/you/.ssh/id_rsa.
Your public key has been saved in /Users/you/.ssh/id_rsa.pub.
The key fingerprint is:
39:fc:ce:94:f4:09:13:95:64:9a:65:c1:de:05:4d:01 you@computer-name
```

Copy your public key and add it to your GitLab profile

```shell
cat ~/.ssh/id_rsa.pub
```

```shell
ssh-rsa AAAAB3NzaC1yc2EAAAADAQEL17Ufacg8cDhlQMS5NhV8z3GHZdhCrZbl4gz you@example.com
```
