---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/repository_mirroring.html'
---

# Repository mirroring **(FREE)**

Repository mirroring allows for the mirroring of repositories to and from external sources. You
can use it to mirror branches, tags, and commits between repositories. It helps you use
a repository outside of GitLab.

A repository mirror at GitLab updates automatically. You can also manually trigger an update:

- At most once every five minutes on GitLab.com.
- According to a [limit set by the administrator](../../../../administration/instance_limits.md#pull-mirroring-interval)
  on self-managed instances.

There are two kinds of repository mirroring supported by GitLab:

- [Push](push.md): for mirroring a GitLab repository to another location.
- [Pull](pull.md): for mirroring a repository from another location to GitLab.

When the mirror repository is updated, all new branches, tags, and commits are visible in the
project's activity feed.

Users with the [Maintainer role](../../../permissions.md) for the project can also force an
immediate update, unless:

- The mirror is already being updated.
- The [limit for pull mirroring interval seconds](../../../../administration/instance_limits.md#pull-mirroring-interval) has not elapsed after its last update.

For security reasons, the URL to the original repository is only displayed to users with the
[Maintainer role](../../../permissions.md) or the [Owner role](../../../permissions.md) for the mirrored
project.

## Use cases

The following are some possible use cases for repository mirroring:

- You migrated to GitLab but still must keep your project in another source. In that case, you
  can set it up to mirror to GitLab (pull) and all the essential history of commits, tags,
  and branches are available in your GitLab instance. **(PREMIUM)**
- You have old projects in another source that you don't use actively anymore, but don't want to
  remove for archiving purposes. In that case, you can create a push mirror so that your active
  GitLab repository can push its changes to the old location.
- You are a GitLab self-managed user for privacy reasons and your instance is closed to the public,
  but you still have certain software components that you want open sourced. In this case, utilizing
  GitLab to be your primary repository which is closed from the public, and using push mirroring to a
  GitLab.com repository that's public, allows you to open source specific projects and contribute back
  to the open source community.

## Mirror only protected branches **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

Based on the mirror direction that you choose, you can opt to mirror only the
[protected branches](../../protected_branches.md) in the mirroring project,
either from or to your remote repository. For pull mirroring, non-protected branches in
the mirroring project are not mirrored and can diverge.

To use this option, check the **Only mirror protected branches** box when
creating a repository mirror. **(PREMIUM)**

## SSH authentication

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22982) in GitLab 11.6 for Push mirroring.

SSH authentication is mutual:

- You have to prove to the server that you're allowed to access the repository.
- The server also has to prove to *you* that it's who it claims to be.

You provide your credentials as a password or public key. The server that the
other repository resides on provides its credentials as a "host key", the
fingerprint of which needs to be verified manually.

If you're mirroring over SSH (using an `ssh://` URL), you can authenticate using:

- Password-based authentication, just as over HTTPS.
- Public key authentication. This is often more secure than password authentication,
  especially when the other repository supports [deploy keys](../../deploy_keys/index.md).

To get started:

1. In your project, go to **Settings > Repository**, and then expand the **Mirroring repositories** section.
1. Enter an `ssh://` URL for mirroring.

NOTE:
SCP-style URLs (that is, `git@example.com:group/project.git`) are not supported at this time.

Entering the URL adds two buttons to the page:

- **Detect host keys**.
- **Input host keys manually**.

If you select the:

- **Detect host keys** button, GitLab fetches the host keys from the server and display the fingerprints.
- **Input host keys manually** button, a field is displayed where you can paste in host keys.

Assuming you used the former, you now must verify that the fingerprints are
those you expect. GitLab.com and other code hosting sites publish their
fingerprints in the open for you to check:

- [AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/regions.html#regions-fingerprints)
- [Bitbucket](https://support.atlassian.com/bitbucket-cloud/docs/configure-ssh-and-two-step-verification/)
- [GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)
- [GitLab.com](../../../gitlab_com/index.md#ssh-host-keys-fingerprints)
- [Launchpad](https://help.launchpad.net/SSHFingerprints)
- [Savannah](http://savannah.gnu.org/maintenance/SshAccess/)
- [SourceForge](https://sourceforge.net/p/forge/documentation/SSH%20Key%20Fingerprints/)

Other providers vary. If you're running self-managed GitLab, or otherwise
have access to the server for the other repository, you can securely gather the
key fingerprints:

```shell
$ cat /etc/ssh/ssh_host*pub | ssh-keygen -E md5 -l -f -
256 MD5:f4:28:9f:23:99:15:21:1b:bf:ed:1f:8e:a0:76:b2:9d root@example.com (ECDSA)
256 MD5:e6:eb:45:8a:3c:59:35:5f:e9:5b:80:12:be:7e:22:73 root@example.com (ED25519)
2048 MD5:3f:72:be:3d:62:03:5c:62:83:e8:6e:14:34:3a:85:1d root@example.com (RSA)
```

NOTE:
You must exclude `-E md5` for some older versions of SSH.

When mirroring the repository, GitLab checks that at least one of the
stored host keys matches before connecting. This can prevent malicious code from
being injected into your mirror, or your password being stolen.

### SSH public key authentication

To use SSH public key authentication, you must also choose that option
from the **Authentication method** dropdown. When the mirror is created,
GitLab generates a 4096-bit RSA key that can be copied by selecting the **Copy SSH public key** button.

![Repository mirroring copy SSH public key to clipboard button](img/repository_mirroring_copy_ssh_public_key_button.png)

You then must add the public SSH key to the other repository's configuration:

- If the other repository is hosted on GitLab, you should add the public SSH key
  as a [deploy key](../../../project/deploy_keys/index.md).
- If the other repository is hosted elsewhere, you must add the key to
  your user's  `authorized_keys` file. Paste the entire public SSH key into the
  file on its own line and save it.

If you must change the key at any time, you can remove and re-add the mirror
to generate a new key. Update the other repository with the new
key to keep the mirror running.

NOTE:
The generated keys are stored in the GitLab database, not in the file system. Therefore,
SSH public key authentication for mirrors cannot be used in a pre-receive hook.

## Force an update **(FREE)**

While mirrors are scheduled to update automatically, you can always force an update by using the
update button which is available on the **Mirroring repositories** section of the **Repository Settings** page.

![Repository mirroring force update user interface](img/repository_mirroring_force_update.png)

## Resources

- Configure a [Pull Mirroring Interval](../../../../administration/instance_limits.md#pull-mirroring-interval)
- [Disable mirrors for a project](../../../admin_area/settings/visibility_and_access_controls.md#enable-project-mirroring)
- [Secrets file and mirroring](../../../../raketasks/backup_restore.md#when-the-secrets-file-is-lost)

## Troubleshooting

Should an error occur during a push, GitLab displays an **Error** highlight for that repository. Details on the error can then be seen by hovering over the highlight text.

### 13:Received RST_STREAM with error code 2 with GitHub

If you receive a "13:Received RST_STREAM with error code 2" message while mirroring to a GitHub repository,
your GitHub settings might be set to block pushes that expose your email address used in commits. Either
set your email address on GitHub to be public, or disable the [Block command line pushes that expose my email](https://github.com/settings/emails) setting.

### 4:Deadline Exceeded

When upgrading to GitLab 11.11.8 or newer, a change in how usernames are represented means that you
must update your mirroring username and password to ensure that `%40` characters are replaced with `@`.

### Connection blocked because server only allows public key authentication

As the error indicates, the connection is getting blocked between GitLab and the remote repository. Even if a
[TCP Check](../../../../administration/raketasks/maintenance.md#check-tcp-connectivity-to-a-remote-site) is successful,
you must check any networking components in the route from GitLab to the remote Server to ensure there's no blockage.

For example, we've seen this error when a Firewall was performing a `Deep SSH Inspection` on outgoing packets.

### Could not read username: terminal prompts disabled

If you receive this error after creating a new project using
[GitLab CI/CD for external repositories](../../../../ci/ci_cd_for_external_repos/):

```plaintext
"2:fetch remote: "fatal: could not read Username for 'https://bitbucket.org': terminal prompts disabled\n": exit status 128."
```

Check if the repository owner is specified in the URL of your mirrored repository:

1. Go to your project.
1. On the left sidebar, select **Settings > Repository**.
1. Select **Mirroring repositories**.
1. If no repository owner is specified, delete and add the URL again in this format:

   ```plaintext
   https://**<repo_owner>**@bitbucket.org/<accountname>/<reponame>.git
   ```

The repository owner is needed for Bitbucket to connect to the repository for mirroring.

### Pull mirror is missing LFS files

In some cases, pull mirroring does not transfer LFS files. This issue occurs when:

- You use an SSH repository URL. The workaround is to use an HTTPS repository URL instead.
  There is [an issue to fix this for SSH URLs](https://gitlab.com/gitlab-org/gitlab/-/issues/11997).
- You're using GitLab 14.0 or older, and the source repository is a public Bitbucket URL.
  This was [fixed in GitLab 14.0.6](https://gitlab.com/gitlab-org/gitlab/-/issues/335123).
- You mirror an external repository using object storage.
  There is [an issue to fix this](https://gitlab.com/gitlab-org/gitlab/-/issues/335495).
