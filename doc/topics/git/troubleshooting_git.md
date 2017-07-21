# Troubleshooting Git

Sometimes things don't work the way they should or as you might expect when
you're using Git. Here are some tips on troubleshooting and resolving issues 
with Git.

## Error Messages

### ‘Broken pipe’ Errors on Git Push

‘Broken pipe’ errors can occur when attempting to push to a remote repository:

```
Write failed: Broken pipe
fatal: The remote end hung up unexpectedly
```

#### If pushing over HTTP

Try increasing the POST buffer size in Git configuration:

```sh
git config http.postBuffer 52428800
```

The value is specified in bytes, so in the above case the buffer size has been 
set to 50MB. The default is 1MB.

#### If pushing over SSH

1. Check SSH configuration:

	‘Broken pipe’ errors can sometimes be caused by underlying issues with SSH 
	(such as authentication), so first check that SSH is correctly configured by
	following the instructions in [SSH Troubleshooting][SSH-Troubleshooting].

1. Prevent session timeouts by configuring SSH ‘keep alive’ either on the client
	or on the server:
	
	>**Note:** configuring *both* the client and the server is unnecessary.

	#### Configure SSH on the client
	
	**On Linux (ssh)**
	
	Edit `~/.ssh/config` (create the file if it doesn’t exist) and insert:
	
	```apache
	Host your-gitlab-instance-url.com
	  ServerAliveInterval 60 
	  ServerAliveCountMax 5	
	```

	**On Windows (PuTTY)**

	In your session properties, go to *Connection* and under 
	`Sending of null packets to keep session active`, set 
	`Seconds between keepalives (0 to turn off)` to 60.

	#### Configure SSH on the server

	Edit `/etc/ssh/sshd_config` and insert:
	
	```apache
	ClientAliveInterval 60
	ClientAliveCountMax 5	
	```

#### If 'pack-objects' type errors are also being displayed

1. Try to run a `git repack` before attempting to push to the remote repository again:

	```
	git repack
	git push 
	```

1. If you’re running an older version of Git (< 2.9), consider upgrading Git to >= 2.9 
(see ‘[Broken pipe when pushing to Git repository][Broken-Pipe]').

[SSH-Troubleshooting]: https://docs.gitlab.com/ce/ssh/README.html#troubleshooting "SSH Troubleshooting"

[Broken-Pipe]: https://stackoverflow.com/questions/19120120/broken-pipe-when-pushing-to-git-repository/36971469#36971469 "StackOverflow: 'Broken pipe when pushing to Git repository'"
