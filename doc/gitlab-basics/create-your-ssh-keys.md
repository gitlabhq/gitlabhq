---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: howto
---

# Create and add your SSH key pair

It's best practice to use [Git over SSH instead of Git over HTTP](https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols).
In order to use SSH, you need to:

1. Create an SSH key pair
1. Add your SSH public key to GitLab

## Creating your SSH key pair

1. Go to your [command line](start-using-git.md#command-shell).
1. Follow the [instructions](../ssh/README.md#generating-a-new-ssh-key-pair) to generate
   your SSH key pair.

## Adding your SSH public key to GitLab

To add the SSH public key to GitLab, see
[Adding an SSH key to your GitLab account](../ssh/README.md#adding-an-ssh-key-to-your-gitlab-account).

NOTE: **Note:**
Once you add a key, you can't edit it. If it did not paste properly, it
[will not work](../ssh/README.md#testing-that-everything-is-set-up-correctly), and
you need to remove the key from GitLab and try adding it again.
