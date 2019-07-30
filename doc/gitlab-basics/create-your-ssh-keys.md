---
type: howto
---

# Create and add your SSH public key

It is best practice to use [Git over SSH instead of Git over HTTP](https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols).
In order to use SSH, you will need to

1. [Create an SSH key pair](#creating-your-ssh-key-pair) on your local computer.
1. [Add the key to GitLab](#adding-your-ssh-public-key-to-gitlab).

## Creating your SSH key pair

1. Go to your [command line](start-using-git.md#open-a-shell).
1. Follow the [instructions](../ssh/README.md#generating-a-new-ssh-key-pair) to generate
   your SSH key pair.

## Adding your SSH public key to GitLab

To add the SSH public key to GitLab, see
[Adding an SSH key to your GitLab account](../ssh/README.md#adding-an-ssh-key-to-your-gitlab-account).

NOTE: **Note:**
Once you add a key, you cannot edit it. If it didn't paste properly, it
[will not work](../ssh/README.md#testing-that-everything-is-set-up-correctly), and
you will need to remove the key from GitLab and try adding it again.
