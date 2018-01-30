---
last_updated: 2017-12-13
---

# Using SSH keys with GitLab CI/CD

GitLab currently doesn't have built-in support for managing SSH keys in a build
environment (where the GitLab Runner runs).

The SSH keys can be useful when:

1. You want to checkout internal submodules
1. You want to download private packages using your package manager (e.g., Bundler)
1. You want to deploy your application to your own server, or, for example, Heroku
1. You want to execute SSH commands from the build environment to a remote server
1. You want to rsync files from the build environment to a remote server

If anything of the above rings a bell, then you most likely need an SSH key.

The most widely supported method is to inject an SSH key into your build
environment by extending your `.gitlab-ci.yml`, and it's a solution which works
with any type of [executor](https://docs.gitlab.com/runner/executors/)
(Docker, shell, etc.).

## How it works

1. Create a new SSH key pair locally with [ssh-keygen](http://linux.die.net/man/1/ssh-keygen)
1. Add the private key as a [secret variable](../variables/README.md) to
   your project
1. Run the [ssh-agent](http://linux.die.net/man/1/ssh-agent) during job to load
   the private key.
1. Copy the public key to the servers you want to have access to (usually in
   `~/.ssh/authorized_keys`) or add it as a [deploy key](../../ssh/README.md#deploy-keys)
   if you are accessing a private GitLab repository.

NOTE: **Note:**
The private key will not be displayed in the job trace, unless you enable
[debug tracing](../variables/README.md#debug-tracing). You might also want to
check the [visibility of your pipelines](../../user/project/pipelines/settings.md#visibility-of-pipelines).

## SSH keys when using the Docker executor

When your CI/CD jobs run inside Docker containers (meaning the environment is
contained) and you want to deploy your code in a private server, you need a way
to access it. This is where an SSH key pair comes in handy.

1. You will first need to create an SSH key pair. For more information, follow
   the instructions to [generate an SSH key](../../ssh/README.md#generating-a-new-ssh-key-pair).
   **Do not** add a passphrase to the SSH key, or the `before_script` will\
   prompt for it.

1. Create a new [secret variable](../variables/README.md#secret-variables).
   As **Key** enter the name `SSH_PRIVATE_KEY` and in the **Value** field paste
   the content of your _private_ key that you created earlier.

1. Modify your `.gitlab-ci.yml` with a `before_script` action. In the following
   example, a Debian based image is assumed. Edit to your needs:

    ```yaml
    before_script:
      ##
      ## Install ssh-agent if not already installed, it is required by Docker.
      ## (change apt-get to yum if you use an RPM-based image)
      ##
      - 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'

      ##
      ## Run ssh-agent (inside the build environment)
      ##
      - eval $(ssh-agent -s)

      ##
      ## Add the SSH key stored in SSH_PRIVATE_KEY variable to the agent store
      ## We're using tr to fix line endings which makes ed25519 keys work
      ## without extra base64 encoding.
      ## https://gitlab.com/gitlab-examples/ssh-private-key/issues/1#note_48526556
      ##
      - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add - > /dev/null

      ##
      ## Create the SSH directory and give it the right permissions
      ##
      - mkdir -p ~/.ssh
      - chmod 700 ~/.ssh

      ##
      ## Optionally, if you will be using any Git commands, set the user name and
      ## and email.
      ##
      #- git config --global user.email "user@example.com"
      #- git config --global user.name "User name"
    ```

    NOTE: **Note:**
    The [`before_script`](../yaml/README.md#before-script) can be set globally
    or per-job.

1. Make sure the private server's [SSH host keys are verified](#verifying-the-ssh-host-keys).

1. As a final step, add the _public_ key from the one you created in the first
   step to the services that you want to have an access to from within the build
   environment. If you are accessing a private GitLab repository you need to add
   it as a [deploy key](../../ssh/README.md#deploy-keys).

That's it! You can now have access to private servers or repositories in your
build environment.

## SSH keys when using the Shell executor

If you are using the Shell executor and not Docker, it is easier to set up an
SSH key.

You can generate the SSH key from the machine that GitLab Runner is installed
on, and use that key for all projects that are run on this machine.

1. First, you need to login to the server that runs your jobs.

1. Then from the terminal login as the `gitlab-runner` user:

    ```
    sudo su - gitlab-runner
    ```

1. Generate the SSH key pair as described in the instructions to
   [generate an SSH key](../../ssh/README.md#generating-a-new-ssh-key-pair).
   **Do not** add a passphrase to the SSH key, or the `before_script` will
   prompt for it.

1. As a final step, add the _public_ key from the one you created earlier to the
   services that you want to have an access to from within the build environment.
   If you are accessing a private GitLab repository you need to add it as a
   [deploy key](../../ssh/README.md#deploy-keys).

Once done, try to login to the remote server in order to accept the fingerprint:

```bash
ssh example.com
```

For accessing repositories on GitLab.com, you would use `git@gitlab.com`.

## Verifying the SSH host keys

It is a good practice to check the private server's own public key to make sure
you are not being targeted by a man-in-the-middle attack. In case anything
suspicious happens, you will notice it since the job would fail (the SSH
connection would fail if the public keys would not match).

To find out the host keys of your server, run the `ssh-keyscan` command from a
trusted network (ideally, from the private server itself):

```sh
## Use the domain name
ssh-keyscan example.com

## Or use an IP
ssh-keyscan 1.2.3.4
```

Create a new [secret variable](../variables/README.md#secret-variables) with
`SSH_KNOWN_HOSTS` as "Key", and as a "Value" add the output of `ssh-keyscan`.

NOTE: **Note:**
If you need to connect to multiple servers, all the server host keys
need to be collected in the **Value** of the variable, one key per line.

TIP: **Tip:**
By using a secret variable instead of `ssh-keyscan` directly inside
`.gitlab-ci.yml`, it has the benefit that you don't have to change `.gitlab-ci.yml`
if the host domain name changes for some reason. Also, the values are predefined
by you, meaning that if the host keys suddenly change, the CI/CD job will fail,
and you'll know there's something wrong with the server or the network.

Now that the `SSH_KNOWN_HOSTS` variable is created, in addition to the
[content of `.gitlab-ci.yml`](#ssh-keys-when-using-the-docker-executor)
above, here's what more you need to add:

 ```yaml
before_script:
  ##
  ## Assuming you created the SSH_KNOWN_HOSTS variable, uncomment the
  ## following two lines.
  ##
  - echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
  - chmod 644 ~/.ssh/known_hosts

  ##
  ## Alternatively, use ssh-keyscan to scan the keys of your private server.
  ## Replace example.com with your private server's domain name. Repeat that
  ## command if you have more than one server to connect to.
  ##
  #- ssh-keyscan example.com >> ~/.ssh/known_hosts
  #- chmod 644 ~/.ssh/known_hosts

  ##
  ## You can optionally disable host key checking. Be aware that by adding that
  ## you are susceptible to man-in-the-middle attacks.
  ## WARNING: Use this only with the Docker executor, if you use it with shell
  ## you will overwrite your user's SSH config.
  ##
  #- '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config'
```

## Example project

We have set up an [Example SSH Project][ssh-example-repo] for your convenience
that runs on [GitLab.com](https://gitlab.com) using our publicly available
[shared runners](../runners/README.md).

Want to hack on it? Simply fork it, commit and push your changes. Within a few
moments the changes will be picked by a public runner and the job will begin.

[ssh-example-repo]: https://gitlab.com/gitlab-examples/ssh-private-key/
