---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Using SSH keys with GitLab CI/CD
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab does not have built-in support for managing SSH keys in a build
environment (where the GitLab Runner runs).

Use SSH keys when you want to:

- Check out internal submodules.
- Download private packages using your package manager. For example, Bundler.
- Deploy your application to your own server or, for example, Heroku.
- Execute SSH commands from the build environment to a remote server.
- Rsync files from the build environment to a remote server.

If anything of the above rings a bell, then you most likely need an SSH key.

The most widely supported method is to inject an SSH key into your build
environment by extending your `.gitlab-ci.yml`, and it's a solution that works
with any type of [executor](https://docs.gitlab.com/runner/executors/)
(like Docker or shell, for example).

## Create and use an SSH key

To create and use an SSH key in GitLab CI/CD:

1. [Create a new SSH key pair](../../user/ssh.md#generate-an-ssh-key-pair) locally with `ssh-keygen`.
1. Add the private key as a [file type CI/CD variable](../variables/_index.md#for-a-project) to
   your project. The variable value must end in a newline (`LF` character). To add a newline, press <kbd>Enter</kbd> or <kbd>Return</kbd>
   at the end of the last line of the SSH key before saving it in the CI/CD settings.
1. Run the [`ssh-agent`](https://linux.die.net/man/1/ssh-agent) in the job, which loads
   the private key.
1. Copy the public key to the servers you want to have access to (usually in `~/.ssh/authorized_keys`).
   If you are accessing a private GitLab repository, you also need to add the public key as
   a [deploy key](../../user/project/deploy_keys/_index.md).

In the following example, the `ssh-add -` command does not display the value of
`$SSH_PRIVATE_KEY` in the job log, though it could be exposed if you enable
[debug logging](../variables/_index.md#enable-debug-logging). You might also want to
check the [visibility of your pipelines](../pipelines/settings.md#change-which-users-can-view-your-pipelines).

## SSH keys when using the Docker executor

When your CI/CD jobs run inside Docker containers (meaning the environment is
contained) and you want to deploy your code in a private server, you need a way
to access it. In this case, you can use an SSH key pair.

1. You first must create an SSH key pair. For more information, follow
   the instructions to [generate an SSH key](../../user/ssh.md#generate-an-ssh-key-pair).
   **Do not** add a passphrase to the SSH key, or the `before_script` will
   prompt for it.

1. Create a new [file type CI/CD variable](../variables/_index.md#for-a-project).
   - In the **Key** field, enter `SSH_PRIVATE_KEY`.
   - In the **Value** field, paste the content of your _private_ key from the key pair that you created earlier.
     Make sure the file ends with a newline. To add a newline, press
     <kbd>Enter</kbd> or <kbd>Return</kbd> at the end of the last line of the SSH key before saving your changes.

1. Modify your `.gitlab-ci.yml` with a `before_script` action. In the following
   example, a Debian based image is assumed. Edit to your needs:

   ```yaml
   before_script:
     ##
     ## Install ssh-agent if not already installed, it is required by Docker.
     ## (change apt-get to yum if you use an RPM-based image)
     ##
     - 'command -v ssh-agent >/dev/null || ( apt-get update -y && apt-get install openssh-client -y )'

     ##
     ## Run ssh-agent (inside the build environment)
     ##
     - eval $(ssh-agent -s)

     ##
     ## Give the right permissions, otherwise ssh-add will refuse to add files
     ## Add the SSH key stored in SSH_PRIVATE_KEY file type CI/CD variable to the agent store
     ##
     - chmod 400 "$SSH_PRIVATE_KEY"
     - ssh-add "$SSH_PRIVATE_KEY"

     ##
     ## Create the SSH directory and give it the right permissions
     ##
     - mkdir -p ~/.ssh
     - chmod 700 ~/.ssh

     ##
     ## Optionally, if you will be using any Git commands, set the user name and
     ## and email.
     ##
     # - git config --global user.email "user@example.com"
     # - git config --global user.name "User name"
   ```

   The [`before_script`](../yaml/_index.md#before_script) can be set as a default
   or per-job.

1. Make sure the private server's [SSH host keys are verified](#verifying-the-ssh-host-keys).

1. As a final step, add the _public_ key from the one you created in the first
   step to the services that you want to have an access to from inside the build
   environment. If you are accessing a private GitLab repository you must add
   it as a [deploy key](../../user/project/deploy_keys/_index.md).

That's it! You can now have access to private servers or repositories in your
build environment.

## SSH keys when using the Shell executor

If you are using the Shell executor and not Docker, it is easier to set up an
SSH key.

You can generate the SSH key from the machine that GitLab Runner is installed
on, and use that key for all projects that are run on this machine.

1. First, sign in to the server that runs your jobs.

1. Then, from the terminal, sign in as the `gitlab-runner` user:

   ```shell
   sudo su - gitlab-runner
   ```

1. Generate the SSH key pair as described in the instructions to
   [generate an SSH key](../../user/ssh.md#generate-an-ssh-key-pair).
   **Do not** add a passphrase to the SSH key, or the `before_script` will
   prompt for it.

1. As a final step, add the _public_ key from the one you created earlier to the
   services that you want to have an access to from inside the build environment.
   If you are accessing a private GitLab repository you must add it as a
   [deploy key](../../user/project/deploy_keys/_index.md).

After generating the key, try to sign in to the remote server to accept the
fingerprint:

```shell
ssh example.com
```

For accessing repositories on GitLab.com, you would use `git@gitlab.com`.

## Verifying the SSH host keys

It is a good practice to check the private server's own public key to make sure
you are not being targeted by a man-in-the-middle attack. If anything
suspicious happens, you notice it because the job fails (the SSH
connection fails when the public keys don't match).

To find out the host keys of your server, run the `ssh-keyscan` command from a
trusted network (ideally, from the private server itself):

```shell
## Use the domain name
ssh-keyscan example.com

## Or use an IP
ssh-keyscan 10.0.2.2
```

Create a new [file type CI/CD variable](../variables/_index.md#use-file-type-cicd-variables)
with `SSH_KNOWN_HOSTS` as "Key", and as a "Value" add the output of `ssh-keyscan`.
Make sure the file ends with a newline. To add a newline, press <kbd>Enter</kbd> or <kbd>Return</kbd>
at the end of the last line of the SSH key before saving your changes.

If you must connect to multiple servers, all the server host keys
must be collected in the **Value** of the variable, one key per line.

NOTE:
By using a file type CI/CD variable instead of `ssh-keyscan` directly inside
`.gitlab-ci.yml`, it has the benefit that you don't have to change `.gitlab-ci.yml`
if the host domain name changes for some reason. Also, the values are predefined
by you, meaning that if the host keys suddenly change, the CI/CD job doesn't fail,
so there's something wrong with the server or the network.

Now that the `SSH_KNOWN_HOSTS` variable is created, in addition to the
[content of `.gitlab-ci.yml`](#ssh-keys-when-using-the-docker-executor)
above, you must add:

```yaml
before_script:
  ##
  ## Assuming you created the SSH_KNOWN_HOSTS file type CI/CD variable, uncomment the
  ## following two lines.
  ##
  - cp "$SSH_KNOWN_HOSTS" ~/.ssh/known_hosts
  - chmod 644 ~/.ssh/known_hosts

  ##
  ## Alternatively, use ssh-keyscan to scan the keys of your private server.
  ## Replace example.com with your private server's domain name. Repeat that
  ## command if you have more than one server to connect to. Include the -t
  ## flag to specify the key type.
  ##
  # - ssh-keyscan -t rsa,ed25519 example.com >> ~/.ssh/known_hosts
  # - chmod 644 ~/.ssh/known_hosts

  ##
  ## You can optionally disable host key checking. Be aware that by adding that
  ## you are susceptible to man-in-the-middle attacks.
  ## WARNING: Use this only with the Docker executor, if you use it with shell
  ## you will overwrite your user's SSH config.
  ##
  # - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" >> ~/.ssh/config'
```

## Use SSH key without a file type CI/CD variable

If you do not want to use a file type CI/CD variable, the [example SSH Project](https://gitlab.com/gitlab-examples/ssh-private-key/)
shows an alternative method. This method uses a regular CI/CD variable instead of
the file type variable recommended above.

## Troubleshooting

### `Error loading key "/builds/path/SSH_PRIVATE_KEY": error in libcrypto` message

This message can be returned if there is a formatting error with the SSH key.

When saving the SSH key as a [file type CI/CD variable](../variables/_index.md#use-file-type-cicd-variables),
the value must end with a newline (`LF` character). To add a newline, press <kbd>Enter</kbd> or <kbd>Return</kbd>
at the end of the `-----END OPENSSH PRIVATE KEY-----` line of the SSH key before saving
the variable.
