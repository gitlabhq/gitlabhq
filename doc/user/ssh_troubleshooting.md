---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting SSH
---

When working with SSH keys, you might encounter the following issues.

## TLS: server sent certificate containing RSA key larger than 8192 bits

In GitLab 16.3 and later, Go limits RSA keys to a maximum of 8192 bits.
To check the length of a key:

```shell
openssl rsa -in <your-key-file> -text -noout | grep "Key:"
```

Replace any key longer than 8192 bits with a shorter key.

## Password prompt with `git clone`

When you run `git clone`, you may be prompted for a password, like `git@gitlab.example.com's password:`.
This indicates that something is wrong with your SSH setup.

- Ensure that you generated your SSH key pair correctly and added the public SSH
  key to your GitLab profile.
- Try to manually register your private SSH key by using `ssh-agent`.
- Try to debug the connection by running `ssh -Tv git@example.com`.
  Replace `example.com` with your GitLab URL.
- Ensure you followed all the instructions in [Use SSH on Microsoft Windows](ssh.md#use-ssh-on-microsoft-windows).
- Ensure that you have [Verify GitLab SSH ownership and permissions](ssh.md#verify-gitlab-ssh-ownership-and-permissions). If you have several hosts ensure that permissions are correct in all hosts.

## `Could not resolve hostname` error

You may receive the following error when [verifying that you can connect](ssh.md#verify-that-you-can-connect):

```shell
ssh: Could not resolve hostname gitlab.example.com: nodename nor servname provided, or not known
```

If you receive this error, restart your terminal and try the command again.

### `Key enrollment failed: invalid format` error

You may receive the following error when [generating an SSH key pair for a FIDO2 hardware security key](ssh.md#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key):

```shell
Key enrollment failed: invalid format
```

You can troubleshoot this by trying the following:

- Run the `ssh-keygen` command using `sudo`.
- Verify your FIDO2 hardware security key supports
  the key type provided.
- Verify the version of OpenSSH is 8.2 or greater by
  running `ssh -V`.

## Error: `SSH host keys are not available on this system.`

If GitLab does not have access to the host SSH keys, when you visit `gitlab.example/help/instance_configuration`, you see the following error message under the **SSH host key fingerprints** header instead of the instance SSH fingerprint:

```plaintext
SSH host keys are not available on this system. Please use ssh-keyscan command or contact your GitLab administrator for more information.
```

To resolve this error:

- On Helm chart (Kubernetes) deployments, update the `values.yaml` to set [`sshHostKeys.mount`](https://docs.gitlab.com/charts/charts/gitlab/webservice/) to `true` under the `webservice` section.
- On GitLab Self-Managed installations, check the `/etc/ssh` directory for the host keys.
