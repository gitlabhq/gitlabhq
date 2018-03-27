---
comments: false
---

# Configure your environment

----------
## Install

- **Windows**
  - Install 'Git for Windows' from https://git-for-windows.github.io

- **Mac**
  - Type '`git`' in the Terminal application.
  - If it's not installed, it will prompt you to install it.

- **Linux**
  ```bash
    sudo yum install git-all
  ```
  ```bash
    sudo apt-get install git-all
  ```

----------

## Configure Git

One-time configuration of the Git client

```bash
git config --global user.name "Your Name"
git config --global user.email you@example.com
```

----------

## Configure SSH Key

```bash
ssh-keygen -t rsa -b 4096 -C "you@computer-name"
```

```bash
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

```bash
cat ~/.ssh/id_rsa.pub
```

```bash
ssh-rsa AAAAB3NzaC1yc2EAAAADAQEL17Ufacg8cDhlQMS5NhV8z3GHZdhCrZbl4gz you@example.com
```
