# SSH

Git is a distributed version control system, which means you can work locally
but you can also share or "push" your changes to other servers.
Before you can push your changes to a GitLab server
you need a secure communication channel for sharing information.
GitLab uses Public-key or asymmetric cryptography
which "encrypts" a communication channel by locking it with your "private key"
and allows trusted parties to unlock it with your "public key".
If someone does not have your public key they cannot access the unencrypted message.

## Locating an existing SSH key pair

Before generating a new SSH key check if your system already has one
at the default location by opening a shell, or Command Prompt on Windows,
and running the following command:

**Windows Command Prompt:**
```bash
type %userprofile%\.ssh\id_rsa.pub
```
**GNU/Linux/Mac/PowerShell:**
```bash
cat ~/.ssh/id_rsa.pub
```

If you see a string starting with `ssh-rsa` you already have an SSH key pair
and you can skip the next step **Generating a new SSH key pair**
and continue onto **Copying your public SSH key to the clipboard**.
If you don't see the string or would like to generate a SSH key pair with a custom name
continue onto the next step.

## Generating a new SSH key pair

To generate a new SSH key, use the following command:

**GNU/Linux/Mac/PowerShell:**
```bash
ssh-keygen -t rsa -C "$your_email"
```

**Windows:**
On Windows you will need to download
[PuttyGen](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html)
and follow this documentation
[article](https://the.earth.li/~sgtatham/putty/0.67/htmldoc/Chapter8.html#pubkey-puttygen)
to generate a SSH key pair.

### Provide a file path

You will be prompted to input a file path to save your key pair to.

If you don't already have an SSH key pair use the suggested path by pressing enter.
Using the suggested path will allow your SSH client
to automatically use the key pair with no additional configuration.

If you already have a key pair with the suggested file path you will need to input a new file path
and declare what host this key pair will be used for in your `.ssh/config` file,
see **Working with non-default SSH key pair paths** for more information.

### Provide a password

Once you have input a file path you will be prompted to input a password to secure your SSH key pair.
Note: It is a best practice to use a password for an SSH key pair,
but it is not required and you can skip creating a password by pressing enter.

If you want to change the password of your key, you can use the following command:
`ssh-keygen -p <keyname>`

## Copying your public SSH key to the clipboard

To copy your public key to the clipboard, use the appropriate code for you operating system below:

**Windows Command Line:**
```bash
type %userprofile%\.ssh\id_rsa.pub | clip
```

**Windows PowerShell:**
```bash
cat ~/.ssh/id_rsa.pub | clip
```

**Mac:**
```bash
pbcopy < ~/.ssh/id_rsa.pub
```

**GNU/Linux (requires xclip):**
```bash
xclip -sel clip < ~/.ssh/id_rsa.pub
```

## Adding your public SSH key to GitLab

Navigate to the 'SSH Keys' tab in you 'Profile Settings'.
Paste your key in the 'Key' section and give it a relevant 'Title'.
Use an identifiable title like 'Work Laptop - Windows 7' or 'Home MacBook Pro 15'.

If you manually copied your public SSH key make sure you copied the entire key
starting with `ssh-rsa` and ending with your email.

## Working with non-default SSH key pair paths

If you used a non-default file path for your GitLab SSH key pair,
you must configure your SSH client to find your GitLab SSH private key
for connections to your GitLab server (perhaps gitlab.com).

For OpenSSH clients this is configured in the `~/.ssh/config` file.
Below are two example host configurations using their own key:

```
# GitLab.com server
Host gitlab.com
RSAAuthentication yes
IdentityFile ~/folder1/private-key-filename
User mygitlabusername

# Private GitLab server
Host gitlab.company.com
RSAAuthentication yes
IdentityFile ~/folder2/private-key-filename
```

Note in the gitlab.com example above a username was specified
to override the default chosen by OpenSSH (your local username).
This is only required if your local and remote usernames differ.

Due to the wide variety of SSH clients and their very large number of configuration options,
further explanation of these topics is beyond the scope of this document.

Public SSH keys need to be unique, as they will bind to your account.
Your SSH key is the only identifier you'll have when pushing code via SSH.
That's why it needs to uniquely map to a single user.

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

Deploy keys can be shared between projects, you just need to add them to each project.

## Applications

### Eclipse

How to add your ssh key to Eclipse: https://wiki.eclipse.org/EGit/User_Guide#Eclipse_SSH_Configuration
