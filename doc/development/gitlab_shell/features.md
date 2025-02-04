---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitLab Shell feature list
---

## Discover

Allows users to identify themselves on an instance with SSH. The command helps to
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
[generate new 2FA recovery codes](../../user/profile/account/two_factor_authentication_troubleshooting.md#generate-new-recovery-codes-using-ssh):

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

Enables users to use personal access tokens with SSH:

```shell
$ ssh git@<hostname> personal_access_token <name> <scope1[,scope2,...]> [ttl_days]

Token:   glpat-...
Scopes:  api
Expires: 2022-02-05
```

### Configuration options

Administrators can control PAT generation with SSH.
To configure PAT settings in GitLab Shell:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit the `/etc/gitlab/gitlab.rb` file.
1. Add or modify the following configuration:

   ```ruby
   gitlab_shell['pat'] = { enabled: true, allowed_scopes: [] }
   ```

   - `enabled`: Set to `true` to enable PAT generation using SSH, or `false` to disable it.
   - `allowed_scopes`: An array of scopes allowed for PATs generated with SSH.
     Leave empty (`[]`) to allow all scopes.

1. Save the file and [Restart GitLab](../../administration/restart_gitlab.md).

:::TabTitle Helm chart (Kubernetes)

1. Edit the `values.yaml` file:

   ```yaml
   gitlab:
     gitlab-shell:
       config:
         pat:
           enabled: true
           allowedScopes: []
   ```

   - `enabled`: Set to `true` to enable PAT generation using SSH, or `false` to disable it.
   - `allowedScopes`: An array of scopes allowed for PATs generated with SSH.
     Leave empty (`[]`) to allow all

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit the `docker-compose.yaml` file:

   ```yaml
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_shell['pat'] = { enabled: true, allowed_scopes: [] }
   ```

   - `enabled`: Set to `'true'` to enable PAT generation using SSH, or `'false'` to disable it.
   - `allowed_scopes`: A comma-separated list of scopes allowed for PATs generated with SSH. Leave empty (`[]`) to allow all scopes.

1. Save the file and restart GitLab and its services:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit the `/home/git/gitlab-shell/config.yml` file:

   ```yaml
   pat:
     enabled: true
     allowed_scopes: []
   ```

   - `enabled`: Set to `true` to enable PAT generation using SSH, or `false` to disable it.
   - `allowed_scopes`: An array of scopes allowed for PATs generated with SSH.
      Leave empty (`[]`) to allow all scopes.

1. Save the file and restart GitLab Shell:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab-shell.target

   # For systems running SysV init
   sudo service gitlab-shell restart
   ```

::EndTabs

NOTE:
These settings only affect PAT generation with SSH and do not
impact PATs created through the web interface.
