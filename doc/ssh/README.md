# SSH

## SSH keys

An SSH key allows you to establish a secure connection between your
computer and GitLab.

Before generating an SSH key, check if your system already has one by
running `cat ~/.ssh/id_rsa.pub`. If you see a long string starting with
`ssh-rsa` or `ssh-dsa`, you can skip the ssh-keygen step.

To generate a new SSH key, just open your terminal and use code below. The
ssh-keygen command prompts you for a location and filename to store the key
pair and for a password. When prompted for the location and filename, you
can press enter to use the default.

It is a best practice to use a password for an SSH key, but it is not
required and you can skip creating a password by pressing enter. Note that
the password you choose here can't be altered or retrieved.

```bash
ssh-keygen -t rsa -C "$your_email"
```

Use the code below to show your public key.

```bash
cat ~/.ssh/id_rsa.pub
```

Copy-paste the key to the 'My SSH Keys' section under the 'SSH' tab in your
user profile. Please copy the complete key starting with `ssh-` and ending
with your username and host.

Use code below to copy your public key to the clipboard. Depending on your
OS you'll need to use a different command:

**Windows:**
```bash
clip < ~/.ssh/id_rsa.pub
```

**Mac:**
```bash
pbcopy < ~/.ssh/id_rsa.pub
```

**GNU/Linux (requires xclip):**
```bash
xclip -sel clip < ~/.ssh/id_rsa.pub
```

## Deploy keys

Deploy keys allow read-only access to multiple projects with a single SSH
key.

This is really useful for cloning repositories to your Continuous
Integration (CI) server. By using deploy keys, you don't have to setup a
dummy user account.

If you are a project master or owner, you can add a deploy key in the
project settings under the section 'Deploy Keys'. Press the 'New Deploy
Key' button and upload a public SSH key. After this, the machine that uses
the corresponding private key has read-only access to the project.

You can't add the same deploy key twice with the 'New Deploy Key' option.
If you want to add the same key to another project, please enable it in the
list that says 'Deploy keys from projects available to you'. All the deploy
keys of all the projects you have access to are available. This project
access can happen through being a direct member of the project, or through
a group. See `def accessible_deploy_keys` in `app/models/user.rb` for more
information.

## Applications

### Eclipse

How to add your ssh key to Eclipse: http://wiki.eclipse.org/EGit/User_Guide#Eclipse_SSH_Configuration

## Tip: Non-default OpenSSH key file names or locations

If, for whatever reason, you decide to specify a non-default location and filename for your Gitlab SSH key pair, you must configure your SSH client to find your Gitlab SSH private key for connections to your Gitlab server (perhaps gitlab.com). For OpenSSH clients, this is handled in the `~/.ssh/config` file with a stanza similar to the following:

```
#
# Main gitlab.com server
#
Host gitlab.com
RSAAuthentication yes
IdentityFile ~/my-ssh-key-directory/my-gitlab-private-key-filename
User mygitlabusername
```

Another example
```
#
# Our company's internal Gitlab server
#
Host my-gitlab.company.com
RSAAuthentication yes
IdentityFile ~/my-ssh-key-directory/company-com-private-key-filename
```

Note in the gitlab.com example above a username was specified to override the default chosen by OpenSSH (your local username). This is only required if your local and remote usernames differ.

Due to the wide variety of SSH clients and their very large number of configuration options, further explanation of these topics is beyond the scope of this document.

Public SSH keys need to be unique, as they will bind to your account. Your SSH key is the only identifier you'll
have when pushing code via SSH. That's why it needs to uniquely map to a single user.
