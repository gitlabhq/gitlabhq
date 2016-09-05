# Using SSH keys

GitLab currently doesn't have built-in support for managing SSH keys in a build
environment.

The SSH keys can be useful when:

1. You want to checkout internal submodules
2. You want to download private packages using your package manager (eg. bundler)
3. You want to deploy your application to eg. Heroku or your own server
4. You want to execute SSH commands from the build server to the remote server
5. You want to rsync files from your build server to the remote server

If anything of the above rings a bell, then you most likely need an SSH key.

## Inject keys in your build server

The most widely supported method is to inject an SSH key into your build
environment by extending your `.gitlab-ci.yml`.

This is the universal solution which works with any type of executor
(docker, shell, etc.).

### How it works

1. Create a new SSH key pair with [ssh-keygen][]
2. Add the private key as a **Secret Variable** to the project
3. Run the [ssh-agent][] during build to load the private key.

## SSH keys when using the Docker executor

You will first need to create an SSH key pair. For more information, follow the
instructions to [generate an SSH key](../../ssh/README.md). Do not add a comment
to the SSH key, or the `before_script` will prompt for a passphrase.

Then, create a new **Secret Variable** in your project settings on GitLab
following **Settings > Variables**. As **Key** add the name `SSH_PRIVATE_KEY`
and in the **Value** field paste the content of your _private_ key that you
created earlier.

Next you need to modify your `.gitlab-ci.yml` with a `before_script` action.
Add it to the top:

```
before_script:
  # Install ssh-agent if not already installed, it is required by Docker.
  # (change apt-get to yum if you use a CentOS-based image)
  - 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'

  # Run ssh-agent (inside the build environment)
  - eval $(ssh-agent -s)

  # Add the SSH key stored in SSH_PRIVATE_KEY variable to the agent store
  - ssh-add <(echo "$SSH_PRIVATE_KEY")

  # For Docker builds disable host key checking. Be aware that by adding that
  # you are suspectible to man-in-the-middle attacks.
  # WARNING: Use this only with the Docker executor, if you use it with shell
  # you will overwrite your user's SSH config.
  - mkdir -p ~/.ssh
  - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config'
```

As a final step, add the _public_ key from the one you created earlier to the
services that you want to have an access to from within the build environment.
If you are accessing a private GitLab repository you need to add it as a
[deploy key](../../ssh/README.md#deploy-keys).

That's it! You can now have access to private servers or repositories in your
build environment.

## SSH keys when using the Shell executor

If you are using the Shell executor and not Docker, it is easier to set up an
SSH key.

You can generate the SSH key from the machine that GitLab Runner is installed
on, and use that key for all projects that are run on this machine.

First, you need to login to the server that runs your builds.

Then from the terminal login as the `gitlab-runner` user and generate the SSH
key pair as described in the [SSH keys documentation](../../ssh/README.md).

As a final step, add the _public_ key from the one you created earlier to the
services that you want to have an access to from within the build environment.
If you are accessing a private GitLab repository you need to add it as a
[deploy key](../../ssh/README.md#deploy-keys).

Once done, try to login to the remote server in order to accept the fingerprint:

```bash
ssh <address-of-my-server>
```

For accessing repositories on GitLab.com, the `<address-of-my-server>` would be
`git@gitlab.com`.

## Example project

We have set up an [Example SSH Project][ssh-example-repo] for your convenience
that runs on [GitLab.com](https://gitlab.com) using our publicly available
[shared runners](../runners/README.md).

Want to hack on it? Simply fork it, commit and push your changes. Within a few
moments the changes will be picked by a public runner and the build will begin.

[ssh-keygen]: http://linux.die.net/man/1/ssh-keygen
[ssh-agent]: http://linux.die.net/man/1/ssh-agent
[ssh-example-repo]: https://gitlab.com/gitlab-examples/ssh-private-key/
