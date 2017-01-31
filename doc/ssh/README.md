# SSH

Git is a distributed version control system, which means you can work locally
but you can also share or "push" your changes to other servers.
Before you can push your changes to a GitLab server
you need a secure communication channel for sharing information.

The SSH protocol provides this security and allows you to authenticate to the
GitLab remote server without supplying your username or password each time.

For a more detailed explanation of how the SSH protocol works, we advise you to
read [this nice tutorial by DigitalOcean](https://www.digitalocean.com/community/tutorials/understanding-the-ssh-encryption-and-connection-process).

## Locating an existing SSH key pair

Before generating a new SSH key check if your system already has one
at the default location by opening a shell, or Command Prompt on Windows,
and running the following command:

**Windows Command Prompt:**

```bash
type %userprofile%\.ssh\id_rsa.pub
```

**GNU/Linux / macOS / PowerShell:**

```bash
cat ~/.ssh/id_rsa.pub
```

If you see a string starting with `ssh-rsa` you already have an SSH key pair
and you can skip the next step **Generating a new SSH key pair**
and continue onto **Copying your public SSH key to the clipboard**.
If you don't see the string or would like to generate a SSH key pair with a
custom name continue onto the next step.

## Generating a new SSH key pair

1. To generate a new SSH key, use the following command:

    **GNU/Linux / macOS:**

    ```bash
    ssh-keygen -t rsa -C "GitLab" -b 4096
    ```

    **Windows:**

    On Windows you will need to download
    [PuttyGen](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html)
    and follow this [documentation article][winputty] to generate a SSH key pair.

1. Next, you will be prompted to input a file path to save your key pair to.

    If you don't already have an SSH key pair use the suggested path by pressing
    enter. Using the suggested path will allow your SSH client
    to automatically use the key pair with no additional configuration.

    If you already have a key pair with the suggested file path, you will need
    to input a new file path and declare what host this key pair will be used
    for in your `.ssh/config` file, see **Working with non-default SSH key pair paths**
    for more information.

1. Once you have input a file path you will be prompted to input a password to
   secure your SSH key pair. It is a best practice to use a password for an SSH
   key pair, but it is not required and you can skip creating a password by
   pressing enter.

     >**Note:**
     If you want to change the password of your key, you can use `ssh-keygen -p <keyname>`.

1. The next step is to copy the public key as we will need it afterwards.

    To copy your public key to the clipboard, use the appropriate code for your
    operating system below:

    **macOS:**

    ```bash
    pbcopy < ~/.ssh/id_rsa.pub
    ```

    **GNU/Linux (requires the xclip package):**

    ```bash
    xclip -sel clip < ~/.ssh/id_rsa.pub
    ```

    **Windows Command Line:**

    ```bash
    type %userprofile%\.ssh\id_rsa.pub | clip
    ```

    **Windows PowerShell:**

    ```bash
    cat ~/.ssh/id_rsa.pub | clip
    ```

1. The final step is to add your public SSH key to GitLab.

    Navigate to the 'SSH Keys' tab in you 'Profile Settings'.
    Paste your key in the 'Key' section and give it a relevant 'Title'.
    Use an identifiable title like 'Work Laptop - Windows 7' or
    'Home MacBook Pro 15'.

    If you manually copied your public SSH key make sure you copied the entire
    key starting with `ssh-rsa` and ending with your email.

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
IdentityFile ~/.ssh/config/private-key-filename-01

# Private GitLab server
Host gitlab.company.com
RSAAuthentication yes
IdentityFile ~/.ssh/config/private-key-filename
```

Due to the wide variety of SSH clients and their very large number of
configuration options, further explanation of these topics is beyond the scope
of this document.

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
a group.

Deploy keys can be shared between projects, you just need to add them to each
project.

## Applications

### Eclipse

How to add your ssh key to Eclipse: https://wiki.eclipse.org/EGit/User_Guide#Eclipse_SSH_Configuration

[winputty]: https://the.earth.li/~sgtatham/putty/0.67/htmldoc/Chapter8.html#pubkey-puttygen
