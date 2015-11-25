# Using SSH keys

GitLab currently doesn't have built-in support for SSH keys in build environment.

The SSH keys can be useful when:
1. You want to checkout internal submodules,
2. You want to download private packages using your package manager (ie. bundler),
3. You want to deploy your app (ex. to Heroku or own server),
4. You want to execute ssh commands from build environment on remote server,
5. You want to rsync files from your build to remote server.

If anyone of the above holds true, then you most likely need SSH key.

There are two possibilities to add SSH keys to build environment.

## Inject keys in your build environment
The most widely supported is to inject SSH key into your build environment by extending your .gitlab-ci.yml.
This is the universal solution which works with any type of executor (docker, shell, etc.).

### How it works?
1. We create a new SSH private key with [ssh-keygen](http://linux.die.net/man/1/ssh-keygen).
2. We add the private key as the Secure Variable to project.
3. We run the [ssh-agent](http://linux.die.net/man/1/ssh-agent) during build to load the private key.

The example [.gitlab-ci.yml](https://gitlab.com/gitlab-examples/ssh-private-key/blob/master/.gitlab-ci.yml) looks like this.

### Make it work?
1. First, go to terminal and generate a new SSH key:
```bash
$ ssh-keygen -t rsa -f my_key

Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in my_key.
Your public key has been saved in my_key.pub.
The key fingerprint is:
SHA256:tBJEfyJUGTMNmPCiPg4UHywHs67MxlM2iEBAlI/W+TY fingeprint
The key's randomart image is:
+---[RSA 2048]----+
|=*. .o++*=       |
|..=  +o..o.      |
|.+++o + + .      |
|+o*=.. + +       |
|o+.=. . S        |
|*.o .E .         |
|o*o . .          |
|.o..             |
|  .              |
+----[SHA256]-----+
```

2. Create a new **Secure Variable** in your project settings on GitLab and name it: `SSH_PRIVATE_KEY`.

3. Copy the content of `my_key` and paste it as a **Value** of **SSH_PRIVATE_KEY**.

4. Next you need to modify your `.gitlab-ci.yml` and at the top of the file add:
```
before_script:
# install ssh-agent (it is required for Docker, change apt-get to yum if you use CentOS-based image)
- 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'

# run ssh-agent (in build environment)
- eval $(ssh-agent -s)

# add ssh key stored in SSH_PRIVATE_KEY variable to the agent store
- ssh-add <(echo "$SSH_PRIVATE_KEY")

# for Docker builds disable host key checking, by adding that you are suspectible to man-in-the-middle attack
- mkdir -p ~/.ssh
- '[[ -f /.dockerinit ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config`
```

5. Add the public key from `my_key.pub` to services that you want to have an access from build.

6. If your builds are run using `shell` executor, you may need to login to server and execute the `ssh <address-of-my-server>` to store the fingerprint of remote server.

## SSH keys when using Shell executor
If use `shell`, not `docker` it can be easier to have the SSH key.

We can generate the SSH key for the machine that holds `gitlab-runner` and use that key for all projects that are run on this machine.

1. First, login to server that runs your builds.

2. From terminal login as `gitlab-runner` user and generate the SSH private key:
```bash
$ ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in ~/.ssh/id_rsa.
Your public key has been saved in ~/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:tBJEfyJUGTMNmPCiPg4UHywHs67MxlM2iEBAlI/W+TY fingeprint
The key's randomart image is:
+---[RSA 2048]----+
|=*. .o++*=       |
|..=  +o..o.      |
|.+++o + + .      |
|+o*=.. + +       |
|o+.=. . S        |
|*.o .E .         |
|o*o . .          |
|.o..             |
|  .              |
+----[SHA256]-----+
```

3. Add the public key from `~/.ssh/id_rsa.pub` to services that you want to have an access from build.

4. Try to login for the first time and accept fingerprint:
```bash
ssh <address-of-my-server
```
