# SSH

## SSH keys

An SSH key allows you to establish a secure connection between your
computer and GitLab. Before generating an SSH key in your shell, check if your system
already has one by running the following command:
```bash
cat ~/.ssh/id_rsa.pub
```
If you see a long string starting with `ssh-rsa` or `ssh-dsa`, you can skip the `ssh-keygen` step.

Note: It is a best practice to use a password for an SSH key, but it is not
required and you can skip creating a password by pressing enter. Note that
the password you choose here can't be altered or retrieved.

To generate a new SSH key, use the following command:
```bash
ssh-keygen -t rsa -C "$your_email"
```
This command will prompt you for a location and filename to store the key
pair and for a password. When prompted for the location and filename, you
can press enter to use the default.

Use the command below to show your public key:
```bash
cat ~/.ssh/id_rsa.pub
```

Copy-paste the key to the 'My SSH Keys' section under the 'SSH' tab in your
user profile. Please copy the complete key starting with `ssh-` and ending
with your username and host.

To copy your public key to the clipboard, use code below. Depending on your
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

Deploy keys can be shared between projects, you just need to add them to each project.

## Test your key

After you have set up your SSH key, you'll have to make sure that you can connect to GitLab. If you have created a passphrase, you will be asked to enter it after the first step.

1. Open a Terminal and run:

		ssh -T git@gitlab.com

2. After you verify the authenticity of the fingerprint in this message:

		The authenticity of host 'gitlab.com (WWW.XXX.YYY.ZZZ)' can't be established.
		ECDSA key fingerprint is SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
		Are you sure you want to continue connecting (yes/no)?

	type `yes` to confirm.

3. If everything went well and your username has been recognized you'll see this welcome message with your full name:

		Welcome to GitLab, John Smith!

	In case you get an "access denied" error, try debugging the connection using this command:

		ssh -Tv git@gitlab.com

## Custom SSH configuration

If you happen to have a custom location and filename for your GitLab SSH key pair, you must configure your SSH client to find your GitLab SSH private key for connections to your GitLab server (perhaps gitlab.com). For OpenSSH clients, this is handled in the `~/.ssh/config` file.

Your gitlab.com configuration would look something like this:

	#
	# Main gitlab.com server
	#
	Host gitlab.com
		User git
		Hostname gitlab.com
		RSAAuthentication yes
		IdentityFile ~/my-ssh-key-directory/my-gitlab-private-key-filename

Note: You should connect using the `git` username, connections with your GitLab username will be refused and you will get an "access denied" error.

And for your self-hosted GitLab server the configuration will look like this:

	#
	# Our company's internal GitLab server
	#
	Host my-gitlab.company.com
		Host my-gitlab.company.com
		RSAAuthentication yes
		IdentityFile ~/my-ssh-key-directory/company-com-private-key-filename

You can find more information on custom SSH configuration in the [official documentation](http://linux.die.net/man/5/ssh_config).

Due to the wide variety of SSH clients and their very large number of configuration options, further explanation of these topics is beyond the scope of this document.

Public SSH keys need to be unique, as they will bind to your account. Your SSH key is the only identifier you'll
have when pushing code via SSH. That's why it needs to uniquely map to a single user.

## Applications

### Eclipse

How to add your ssh key to Eclipse: http://wiki.eclipse.org/EGit/User_Guide#Eclipse_SSH_Configuration
