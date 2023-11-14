---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# GitLab Shell feature list

## Discover

Allows users to identify themselves on an instance via SSH. The command helps to
confirm quickly whether a user has SSH access to the instance:

```shell
ssh git@<hostname>

PTY allocation request failed on channel 0
Welcome to GitLab, @username!
Connection to staging.gitlab.com closed.
```

When permission is denied, it returns:

```shell
ssh git@<hostname>
git@<hostname>: Permission denied (publickey).
```

## Git operations

GitLab Shell provides support for Git operations over SSH by processing
`git-upload-pack`, `git-receive-pack` and `git-upload-archive` SSH commands.
It limits the set of commands to predefined Git commands:

- `git archive`
- `git clone`
- `git pull`
- `git push`

## Generate new 2FA recovery codes

Enables users to
[generate new 2FA recovery codes](../../user/profile/account/two_factor_authentication.md#generate-new-recovery-codes-using-ssh):

```shell
$ ssh git@<hostname> 2fa_recovery_codes

Are you sure you want to generate new two-factor recovery codes?
Any existing recovery codes you saved will be invalidated. (yes/no)
yes

Your two-factor authentication recovery codes are:
...
```

## Verify 2FA OTP

Allows users to verify their
[2FA one-time password (OTP)](../../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations):

```shell
$ ssh git@<hostname> 2fa_verify

OTP: 347419

OTP validation failed.
```

## LFS authentication

Enables users to generate credentials for LFS authentication:

```shell
$ ssh git@<hostname> git-lfs-authenticate <project-path> <upload/download>

{"header":{"Authorization":"Basic ..."},"href":"https://gitlab.com/user/project.git/info/lfs","expires_in":7200}
```

## Personal access token

Enables users to use personal access tokens via SSH:

```shell
$ ssh git@<hostname> personal_access_token <name> <scope1[,scope2,...]> [ttl_days]

Token:   glpat-...
Scopes:  api
Expires: 2022-02-05
```
