---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure instance-level SSH certificate authentication with gitlab-sshd using trusted CA keys.
title: Instance-level SSH certificates with `gitlab-sshd`
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-shell/-/merge_requests/1396) in GitLab 18.11.

{{< /history >}}

If your GitLab Self-Managed instance uses `gitlab-sshd`, you can configure
instance-level SSH certificate authentication.

- Use Certificate Authority (CA) certificates to centrally manage SSH authentication.
- No Rails API calls or database changes are required.

This approach is the `gitlab-sshd` equivalent of the OpenSSH
`TrustedUserCAKeys` directive and is an alternative to the
[OpenSSH-based SSH certificate setup](ssh_certificates.md).

## `gitlab_sshd` authentication workflow

The `gitlab_sshd` authentication workflow follows this process.

1. The administrator generates a CA key pair.
1. The administrator adds the CA public key file path under `sshd.trusted_user_ca_keys` to `config.yml`.
1. The administrator signs users' SSH public keys with the CA private key.
   The certificate `KeyId` is set to the user's GitLab username.
1. When the user connects with a certificate:
   - `gitlab-sshd` validates the certificate signature and expiry.
   - `gitlab-sshd` extracts the `KeyId` and uses it as the GitLab username.
   - Standard GitLab access checks proceed (user existence, project permissions).

The `gitlab-sshd` process does not need a Rails API or database call for
the certificate validation itself. The `/allowed` endpoint is
still called for authorization, as with any SSH connection.

## Comparison with other SSH certificate methods

GitLab supports several SSH certificate authentication approaches:

| Feature | Instance-level (`gitlab-sshd`) | Instance-level (OpenSSH) | Group-level |
|---|---|---|---|
| Configuration location | `config.yml` | `sshd_config` | GitLab API/UI |
| SSH server | `gitlab-sshd` | OpenSSH | `gitlab-sshd` |
| Offering | GitLab Self-Managed | GitLab Self-Managed | GitLab.com |
| Tier | Free, Premium, Ultimate | Free, Premium, Ultimate | Premium, Ultimate |
| Scope | Instance-wide (no namespace restriction) | Instance-wide (no namespace restriction) | Top-level group |
| Username mapping | Certificate `KeyId` | Certificate Key ID through `AuthorizedPrincipalsCommand` | Certificate identity through API |
| Enterprise user requirement | No | No | Yes |
| Documentation | This page | [OpenSSH `AuthorizedPrincipalsCommand`](ssh_certificates.md) | [Group SSH certificates](../../user/group/ssh_certificates.md) |

## Prerequisites

Before you configure instance-level SSH certificates:

- Your GitLab Self-Managed instance must have `gitlab-sshd`
  enabled. For more information, see
  [Enable `gitlab-sshd`](gitlab_sshd.md#enable-gitlab-sshd).
- You must have access to the server file system to create CA
  keys and edit `config.yml`.
- The `KeyId` field of the SSH certificate must match the exact
  GitLab username.

## Configure trusted CA keys

To configure instance-level SSH certificate authentication:

1. Generate a CA key pair:

   ```shell
   ssh-keygen -t ed25519 -f ssh_user_ca -C "GitLab SSH User CA"
   ```

   When prompted, enter a strong passphrase to protect the
   CA private key.

   This command creates two files:

   - `ssh_user_ca`: The CA private key.
   - `ssh_user_ca.pub`: The CA public key.

   Copy only the public key to the GitLab server:

   ```shell
   sudo cp ssh_user_ca.pub /etc/gitlab/ssh_user_ca.pub
   ```

   Store the CA private key in a secure location, ideally on
   an offline system that is not the GitLab server. The
   private key is needed only to sign user certificates.

1. Add the CA public key file path to the `gitlab-sshd`
   configuration.

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   1. Edit `/etc/gitlab/gitlab.rb`:

      ```ruby
      gitlab_sshd['trusted_user_ca_keys'] = ['/etc/gitlab/ssh_user_ca.pub']
      ```

   1. Save the file and reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Helm chart (Kubernetes)" >}}

   1. Create a Kubernetes Secret containing the CA public key:

      ```shell
      kubectl create secret generic my-ssh-ca-keys \
        --from-file=ca.pub=ssh_user_ca.pub
      ```

   1. Export the Helm values:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Edit `gitlab_values.yaml` to reference the secret:

      ```yaml
      gitlab:
        gitlab-shell:
          sshDaemon: gitlab-sshd
          config:
            trustedUserCAKeys:
              secret: my-ssh-ca-keys
              keys:
                - ca.pub
      ```

   1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

   For more information about the Helm chart configuration, see the
   [GitLab Shell chart documentation](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#instance-level-ssh-certificates-gitlab-sshd).

   {{< /tab >}}

   {{< /tabs >}}

1. Verify `gitlab-sshd` started successfully by checking the
   logs for:

   ```plaintext
   Loaded trusted user CA keys for instance-level SSH certificates count=1
   ```

## Issue SSH certificates for users

After you configure trusted CA keys, issue certificates for
your users:

1. Obtain the user's public SSH key
   (for example, `id_ed25519.pub`).

1. Sign the user's public key with the CA, setting the `-I`
   (identity/KeyId) flag to the user's exact GitLab username:

   ```shell
   ssh-keygen -s ssh_user_ca -I <gitlab-username> -V +1d user-key.pub
   ```

   This command creates a certificate file
   (for example, `user-key-cert.pub`) that is valid for one day.

   To set a longer validity period, adjust the `-V` flag.
   For example, `-V +30d` for 30 days or `-V +52w` for
   one year.

1. Distribute the certificate file to the user.

1. The user connects using their certificate:

   ```shell
   ssh git@gitlab.example.com
   ```

   If the certificate file follows the default naming convention
   (`<key>-cert.pub` alongside `<key>`), SSH uses it
   automatically. Otherwise, specify the certificate explicitly:

   ```shell
   ssh -o CertificateFile=~/.ssh/id_ed25519-cert.pub git@gitlab.example.com
   ```

## Use multiple certificate authorities

You can specify multiple CA public key files for CA rotation
or multi-CA setups.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_sshd['trusted_user_ca_keys'] = [
     '/etc/gitlab/ssh_user_ca_current.pub',
     '/etc/gitlab/ssh_user_ca_next.pub'
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Create a Kubernetes Secret containing both CA public keys:

   ```shell
   kubectl create secret generic my-ssh-ca-keys \
     --from-file=ca_current.pub=ssh_user_ca_current.pub \
     --from-file=ca_next.pub=ssh_user_ca_next.pub
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml` to reference the secret:

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
       config:
         trustedUserCAKeys:
           secret: my-ssh-ca-keys
           keys:
             - ca_current.pub
             - ca_next.pub
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

A single file can also contain multiple CA public keys, one per
line. `gitlab-sshd` automatically deduplicates keys across files.

## Security considerations

Instance-level SSH certificates grant authentication authority
to anyone who holds the CA private key. Review the following
security considerations before you deploy.

> [!warning]
> Anyone with access to the CA private key can sign certificates
> for **any** GitLab user on the instance. Protect the CA private
> key with appropriate access controls, such as restrictive file
> permissions, hardware security modules (HSMs), or an
> offline environment.

### No certificate revocation

`gitlab-sshd` does not include a built-in certificate revocation
mechanism. If a certificate or CA key is compromised, remove the
CA from the `trusted_user_ca_keys` configuration and reissue
certificates with a new CA. Use short-lived certificates
(for example, 24 hours) to minimize the window of exposure.

### No audit events for CA configuration changes

GitLab does not record changes to `trusted_user_ca_keys` in
`config.yml` as audit events. Monitor changes to this
configuration file by using your infrastructure monitoring tools.

`gitlab-sshd` logs successful and failed SSH certificate
authentication attempts with fields including `ssh_user`,
`public_key_fingerprint`, `signing_ca_fingerprint`,
`certificate_identity`, and `certificate_username`.

### Clustered deployments

In environments with multiple `gitlab-sshd` nodes, synchronize
the configuration and CA public key files across all nodes.
Inconsistent configurations can cause intermittent
authentication failures. For Helm chart deployments, the
Kubernetes Secret is shared across pods automatically.

## Troubleshooting

### `gitlab-sshd` fails to start after adding CA keys

If a CA key file cannot be read or contains content that's not valid,
`gitlab-sshd` does not start. Check the log output for error
messages such as:

- `failed to load trusted user CA keys`: The file could not be
  read. Verify the file exists and has correct permissions
  (readable by the `git` user).
- `failed to parse trusted user CA key in file`: The file
  content is not a valid SSH public key. Verify the file
  contains a valid public key in OpenSSH format.
- `trusted_user_ca_keys configured but no valid CA keys were loaded`:
  The configuration lists CA key files but none contained
  valid keys.

### `certificate rejected: not a user certificate`

The certificate was generated as a host certificate instead of
a user certificate. Do not use the `-h` flag when signing with
`ssh-keygen`.

### `certificate KeyId does not match GitLab username format`

The `KeyId` in the certificate does not conform to GitLab
username rules. Verify the `-I` value used during signing
matches the exact GitLab username.

### `ssh: cert has expired`

The certificate validity period has passed. Issue a new
certificate with an appropriate validity window by using the
`-V` flag.
